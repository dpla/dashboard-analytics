class WebsiteEventTotals
  include GaErrorTracking
  include GaCacheable

  ##
  # @return [WebsiteEventTotals]
  #
  # @example
  #   WebsiteEventTotals.build do |builder|
  #     builder.hub = "California Digital Library"
  #     builder.contributor = "Agua Caliente Cultural Museum"
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

  def view_events
    item_events + exhibit_events + pss_events
  end

  def item_events
    parse_response['View Item'].to_i
  end

  def exhibit_events
    parse_response['View Exhibition Item'].to_i
  end

  def pss_events
    parse_response['View Primary Source'].to_i
  end

  def click_throughs
    parse_response['Click Through'].to_i
  end

  # Counts by event name, summed across eras. nil on error (see #error?).
  # Source set views come from page views instead (see PssEvents).
  def response
    @response ||= merge(era_responses, source_set_views)
  rescue => e
    Rails.logger.error(e)
    record_ga_error(e)
    nil
  end

  private

  def builder_for(era)
    GaResponseBuilder.build do |builder|
      builder.start_date = era.start_date.iso8601
      builder.end_date = era.end_date.iso8601
      builder.metrics = %w(ga:totalEvents)
      builder.dimensions = [era.schema::EVENT_DIMENSION]
      builder.filters = era.schema.hub_filters(@hub, @contributor)
    end
  end

  # Returns 0 on error. The view shows nothing when the count is 0.
  def source_set_views
    PssEvents.build do |builder|
      builder.hub = @hub
      builder.contributor = @contributor
      builder.start_date = @start_date
      builder.end_date = @end_date
    end.total_views
  rescue => e
    Rails.logger.error(e)
    0
  end

  # Rows of [event name, count], one row per name.
  def merge(responses, source_set_views)
    counts = Hash.new(0)
    eras.zip(responses) do |era, response|
      response.rows.to_a.each do |value, count|
        name = era.schema.event_name(value)
        counts[name] += count.to_i if name
      end
    end
    counts['View Primary Source'] = source_set_views
    build_response(%w(ga:eventCategory ga:totalEvents),
                   counts.map { |name, count| [name, count.to_s] })
  end

  # { "View Item" => 12, ... }. Empty hash on error.
  def parse_response
    (response&.rows || []).to_h { |name, count| [name, count.to_i] }
  end
end
