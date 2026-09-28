##
# Months with dp.la activity, from a GA4 report keyed by yearMonth.
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

  # Cached rows of [yearMonth, eventCount] across eras, earliest first.
  # nil on error (see #error?).
  def response
    @response ||= merge(era_responses)
  rescue => e
    Rails.logger.error(e)
    record_ga_error(e)
    nil
  end

  # First day of the earliest month with activity. nil when there is none.
  def earliest_month
    month = response&.rows&.map(&:first)&.find { |m| m.to_s.match?(/\A\d{6}\z/) }
    Date.strptime(month, "%Y%m") if month
  end

  private

  # With no hub, the report covers the whole site.
  def builder_for(era)
    GaResponseBuilder.build do |builder|
      builder.start_date = era.start_date.iso8601
      builder.end_date = era.end_date.iso8601
      builder.metrics = %w(ga:totalEvents)
      builder.dimensions = %w(yearMonth)
      builder.sort = %w(yearMonth)
      builder.filters = @hub ? era.schema.hub_filters(@hub, @contributor) : []
    end
  end

  # If the switch date falls inside a month, the two parts add up.
  def merge(responses)
    counts = Hash.new(0)
    responses.each do |response|
      response.rows.to_a.each { |month, count| counts[month] += count.to_i }
    end
    build_response(%w(yearMonth ga:totalEvents), counts.sort.map { |month, count| [month, count.to_s] })
  end
end
