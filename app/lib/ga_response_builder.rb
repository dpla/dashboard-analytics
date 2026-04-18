require 'google/apis/analyticsdata_v1beta'

class GaResponseBuilder

  # GA4 silently truncates event names to this length at ingestion time.
  # Filters on eventName must use the same limit or they return 0 results.
  GA4_EVENT_NAME_MAX_LENGTH = 40

  GA4_METRICS = {
    'ga:totalEvents'   => 'eventCount',
    'ga:sessions'      => 'sessions',
    'ga:users'         => 'totalUsers',
    'ga:searchUniques' => 'eventCount',
  }.freeze

  GA4_DIMENSIONS = {
    'ga:eventCategory' => 'customEvent:event_category',
    'ga:eventAction'   => 'eventName',
    'ga:eventLabel'    => 'customEvent:event_label',
    'ga:searchKeyword' => 'searchTerm',
  }.freeze

  # When these UA metrics are requested, add an implicit event name filter
  IMPLICIT_EVENT_FILTERS = {
    'ga:searchUniques' => 'view_search_results',
  }.freeze

  def self.build
    builder = new
    yield(builder)
    builder.authorize
    builder
  end

  # Send multiple GA4 report requests in a single HTTP call.
  # Takes an array of already-built GaResponseBuilder instances and
  # returns an array of Ga4Response objects in the same order.
  def self.batch_responses(builders)
    return [] if builders.empty?

    retries = 0
    service  = nil
    begin
      service = builders.first.analytics
      service.authorization = GaAuthorizer.credentials

      property  = "properties/#{Settings.google_analytics.property_id}"
      requests  = builders.map { |b| b.build_request(b.offset) }
      batch_req = Google::Apis::AnalyticsdataV1beta::BatchRunReportsRequest.new(requests: requests)
      batch_resp = service.batch_property_run_reports(property, batch_req)

      batch_resp.reports.each_with_index.map do |report, i|
        b = builders[i]
        Ga4Response.new(report, b.dimensions, b.metrics)
      end
    rescue Google::Apis::AuthorizationError
      raise unless service
      retries += 1
      raise if retries > 3
      service.authorization = GaAuthorizer.credentials
      retry
    rescue => e
      Rails.logger.error(e)
      Sentry.capture_exception(e)
      raise
    end
  end

  # GA4 API read timeout. Chosen to be well under the ALB's 60s idle timeout so
  # that slow queries fail fast and return a graceful error rather than a 504.
  GA4_READ_TIMEOUT_SEC = 25

  def initialize
    @analytics = Google::Apis::AnalyticsdataV1beta::AnalyticsDataService.new
    @analytics.client_options.read_timeout_sec = GA4_READ_TIMEOUT_SEC
    @metrics    = []
    @dimensions = []
    @filters    = []
    @sort       = nil
    @start_date = nil
    @end_date   = nil
    @offset     = 0
  end

  # profile_id and segment are UA concepts — accepted for interface compatibility but ignored
  def profile_id=(profile_id); end
  def segment=(segment); end

  def start_index=(idx); @offset = [idx.to_i - 1, 0].max; end
  def start_date=(v); @start_date = v; end
  def end_date=(v); @end_date = v; end
  def metrics=(v); @metrics = Array(v); end
  def dimensions=(v); @dimensions = Array(v); end
  def filters=(v); @filters = Array(v); end
  def sort=(v); @sort = Array(v); end

  def authorize
    @analytics.authorization = GaAuthorizer.credentials
  end

  def response
    return nil if @metrics.empty?

    retries = 0
    begin
      result = @analytics.run_property_report(property_id, build_request(@offset))
      Ga4Response.new(result, @dimensions, @metrics)
    rescue Google::Apis::AuthorizationError
      retries += 1
      raise if retries > 3
      authorize
      retry
    rescue => e
      Rails.logger.error(e)
      raise
    end
  end

  def multi_page_response(max_pages: 10)
    results = []
    offset  = 0
    limit   = 10_000
    page    = 0

    loop do
      @offset = offset
      resp = response
      break unless resp&.rows&.any?
      results << resp
      page += 1

      if page >= max_pages
        Rails.logger.warn(
          "GaResponseBuilder: multi_page_response hit max_pages=#{max_pages} " \
          "(#{page * limit} rows). Some data may be truncated."
        )
        break
      end

      break unless resp.row_count > offset + limit
      offset += limit
    end

    results
  end

  public

  attr_reader :analytics, :dimensions, :metrics, :offset

  def build_request(offset)
    params = {
      metrics:             ga4_metric_names.map { |m| Google::Apis::AnalyticsdataV1beta::Metric.new(name: m) },
      dimensions:          ga4_dimension_names.map { |d| Google::Apis::AnalyticsdataV1beta::Dimension.new(name: d) },
      date_ranges:         [Google::Apis::AnalyticsdataV1beta::DateRange.new(start_date: @start_date, end_date: @end_date)],
      metric_aggregations: ['TOTAL'],
      keep_empty_rows:     false,
      limit:               10_000,
      offset:              offset
    }
    # Only include optional collection fields when non-nil; passing nil for a
    # collection field causes the representable serializer to crash.
    filter    = build_filter_expression
    order_bys = build_order_bys
    params[:dimension_filter] = filter    if filter
    params[:order_bys]        = order_bys if order_bys
    Google::Apis::AnalyticsdataV1beta::RunReportRequest.new(**params)
  end

  private

  def property_id
    "properties/#{Settings.google_analytics.property_id}"
  end

  def ga4_metric_names
    @metrics.map { |m| GA4_METRICS[m] || m }
  end

  def ga4_dimension_names
    @dimensions.map { |d| GA4_DIMENSIONS[d] || d }
  end

  def build_filter_expression
    exprs = @filters.map { |f| parse_filter(f) }.compact

    @metrics.each do |m|
      next unless IMPLICIT_EVENT_FILTERS[m]
      exprs << make_string_filter('eventName', IMPLICIT_EVENT_FILTERS[m], 'EXACT')
    end

    return nil  if exprs.empty?
    return exprs.first if exprs.length == 1

    Google::Apis::AnalyticsdataV1beta::FilterExpression.new(
      and_group: Google::Apis::AnalyticsdataV1beta::FilterExpressionList.new(expressions: exprs)
    )
  end

  def parse_filter(filter_str)
    if (m = filter_str.match(/\A([^=!]+)==(.+)\z/))
      field = GA4_DIMENSIONS[m[1]] || m[1]
      value = field == 'eventName' ? m[2][0, GA4_EVENT_NAME_MAX_LENGTH] : m[2]
      make_string_filter(field, value, 'EXACT')
    elsif (m = filter_str.match(/\A([^=!]+)=@(.+)\z/))
      make_string_filter(GA4_DIMENSIONS[m[1]] || m[1], m[2], 'CONTAINS')
    elsif (m = filter_str.match(/\A([^=!]+)!@(.+)\z/))
      Google::Apis::AnalyticsdataV1beta::FilterExpression.new(
        not_expression: make_string_filter(GA4_DIMENSIONS[m[1]] || m[1], m[2], 'CONTAINS')
      )
    end
  end

  def make_string_filter(field, value, match_type)
    Google::Apis::AnalyticsdataV1beta::FilterExpression.new(
      filter: Google::Apis::AnalyticsdataV1beta::Filter.new(
        field_name:    field,
        string_filter: Google::Apis::AnalyticsdataV1beta::StringFilter.new(
          match_type:     match_type,
          value:          value,
          case_sensitive: false
        )
      )
    )
  end

  def build_order_bys
    return nil unless @sort&.any?

    @sort.map do |s|
      desc = s.start_with?('-')
      name = desc ? s[1..] : s

      if GA4_METRICS.key?(name)
        Google::Apis::AnalyticsdataV1beta::OrderBy.new(
          metric: Google::Apis::AnalyticsdataV1beta::MetricOrderBy.new(metric_name: GA4_METRICS[name]),
          desc:   desc
        )
      else
        Google::Apis::AnalyticsdataV1beta::OrderBy.new(
          dimension: Google::Apis::AnalyticsdataV1beta::DimensionOrderBy.new(dimension_name: GA4_DIMENSIONS[name] || name),
          desc:      desc
        )
      end
    end
  end

  ##
  # Wraps a GA4 RunReportResponse to present the same interface as the old
  # UA GaData response, minimising changes to callers.
  class Ga4Response
    ColumnHeader = Struct.new(:name)
    QueryStub    = Struct.new(:start_index)
    def initialize(ga4_response, dimension_names, metric_names)
      @response        = ga4_response
      @dimension_names = dimension_names
      @metric_names    = metric_names
    end

    # Returns rows as arrays of plain strings, dimensions first then metrics —
    # same shape as the old UA GaData rows.
    def rows
      return nil unless @response&.rows

      @response.rows.map do |row|
        (row.dimension_values || []).map(&:value) +
          (row.metric_values || []).map(&:value)
      end
    end

    # Keyed by the original UA metric names (e.g. 'ga:totalEvents') so existing
    # callers need no changes.
    def totals_for_all_results
      return {} unless @response&.totals&.any?

      totals_row = @response.totals.first
      return {} if totals_row.metric_values.nil?

      @metric_names.each_with_index.each_with_object({}) do |(name, i), hash|
        hash[name] = totals_row.metric_values[i]&.value
      end
    end

    # Column headers use the original UA names so callers can do
    # columns.index("ga:eventAction") etc. without changes.
    def column_headers
      (@dimension_names + @metric_names).map { |n| ColumnHeader.new(n) }
    end

    def total_results
      @response&.row_count || 0
    end

    # GA4 returns all rows at once; expose total as items_per_page so
    # the "Showing X-Y of Z" pagination UI shows the full count.
    def items_per_page
      total_results
    end

    # Provides response.query.start_index = 1 for the pagination UI.
    def query
      QueryStub.new(1)
    end

    def row_count
      total_results
    end

    def present?
      @response.present?
    end
  end
end
