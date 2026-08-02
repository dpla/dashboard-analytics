##
# Months with dp.la activity, from one GA4 report keyed by yearMonth.
# Feeds the date-menu floor (see GaDataFloor).
#
class WebsiteActivityMonths
  include GaErrorTracking
  include GaCacheable

  ##
  # @return [WebsiteActivityMonths]
  #
  # @example
  #   WebsiteActivityMonths.build do |builder|
  #     builder.hub = "California Digital Library"
  #     builder.start_date = Date.new(2018, 1, 1)
  #     builder.end_date = Date.new(2026, 6, 30)
  #   end
  #
  def self.build
    builder = new
    yield(builder)
    builder
  end

  def initialize
    @hub = nil
    @contributor = nil
    @start_date = nil
    @end_date = nil
  end

  def hub=(hub)
    @hub = hub
  end

  def contributor=(contributor)
    @contributor = contributor
  end

  def start_date=(start_date)
    @start_date = start_date
  end

  def end_date=(end_date)
    @end_date = end_date
  end

  # Memoized builder for the warm job's batched GA4 calls.
  def ga_builder
    @ga_builder ||= activity_months_builder
  end

  ##
  # Cached response; nil on error (see #error?).
  #
  def response
    @response ||= fetch_cached do
      activity_months_builder.response
    end
  rescue => e
    Rails.logger.error(e)
    record_ga_error(e)
    nil
  end

  ##
  # First day of the earliest month with activity; nil when none.
  #
  def earliest_month
    month = response&.rows&.map(&:first)&.find { |m| m.to_s.match?(/\A\d{6}\z/) }
    Date.strptime(month, "%Y%m") if month
  end

  private

  ##
  # Rows: [yearMonth, eventCount], earliest first. No hub = site-wide.
  #
  # @return GaResponseBuilder
  # @throws exception if HTTP request fails
  #
  def activity_months_builder
    filters = []
    filters = %W(ga:eventCategory=@#{@hub} ga:eventCategory!@Browse) if @hub
    filters.concat %W(ga:eventAction==#{@contributor}) if @contributor

    GaResponseBuilder.build do |builder|
      builder.start_date = @start_date.iso8601
      builder.end_date = @end_date.iso8601
      builder.metrics = %w(ga:totalEvents)
      builder.dimensions = %w(yearMonth)
      builder.sort = %w(yearMonth)
      builder.filters = filters
    end
  end
end
