class WebsiteOverviewByContributor
  include GaCacheable

  METRICS = %w(ga:sessions ga:users).freeze

  ##
  # @return [WebsiteOverviewByContributor]
  #
  # @example
  #   WebsiteOverviewByContributor.build do |builder|
  #     builder.hub = "California Digital Library"
  #     builder.start_date = Date.yesterday
  #     builder.end_date = Date.today
  #   end
  #
  def self.build
    builder = new
    yield(builder)
    builder
  end

  def initialize
    @hub = nil
    @start_date = nil
    @end_date = nil
  end

  def hub=(hub)
    @hub = hub
  end

  def start_date=(start_date)
    @start_date = start_date
  end

  def end_date=(end_date)
    @end_date = end_date
  end

  def parse_data
    return Hash.new unless response.present? && response.rows.present?
    # Create Hash of data
    # e.g. "The Library" => { "Sessions" => 4, "Users" => 2 }
    columns = response.column_headers.map { |c| c.name }
    data = {}

    response.rows.map do |r|
      contributor = r[columns.index("ga:eventAction")]
      sessions = r[columns.index("ga:sessions")]
      users = r[columns.index("ga:users")]
      data[contributor] = { 'Sessions' => sessions.to_i,
                            'Users' => users.to_i }
    end

    data
  end

  # Cached rows of [contributor, sessions, users], summed across eras, so
  # a returning visitor counts once per era. nil on error.
  def response
    @response ||= merge(era_responses)
  rescue => e
    Rails.logger.error(e)
    nil
  end

  private

  def builder_for(era)
    GaResponseBuilder.build do |builder|
      builder.start_date = era.start_date.iso8601
      builder.end_date = era.end_date.iso8601
      builder.metrics = METRICS
      builder.dimensions = [era.schema::CONTRIBUTOR_DIMENSION]
      builder.filters = era.schema.hub_filters(@hub)
    end
  end

  def merge(responses)
    totals = Hash.new { |hash, contributor| hash[contributor] = [0, 0] }
    responses.each do |response|
      response.rows.to_a.each do |contributor, sessions, users|
        sums = totals[GaEventSchema.contributor_key(contributor)]
        sums[0] += sessions.to_i
        sums[1] += users.to_i
      end
    end
    rows = totals.map { |contributor, (sessions, users)| [contributor, sessions.to_s, users.to_s] }
    build_response(%w(ga:eventAction) + METRICS, rows)
  end
end
