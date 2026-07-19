class WebsiteEvents
  include GaCacheable

  ##
  # @return [WebsiteEvents]
  #
  # @example
  #   WebsiteEvents.build do |builder|
  #     builder.hub = "California Digital Library"
  #     builder.contributor = "Agua Caliente Cultural Museum"
  #     builder.start_date = Date.yesterday
  #     builder.end_date = Date.today
  #     builder.event_name = "Click Through"
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
    @event_name = nil
    @page = nil
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

  def event_name=(event_name)
    @event_name = event_name
  end

  def event_name
    @event_name
  end

  # 1-based page for #response; CSV exports are unaffected.
  def page=(page)
    @page = page
  end

  ##
  # Lazy load single-page response.
  # Return nil if response fails.
  #
  # @return [Google::Apis::AnalyticsV3::GaData] | nil
  #
  def response
    @response ||= Rails.cache.fetch("#{cache_key}:page#{@page}", expires_in: 2.hours) do
      events_builder.response
    end
  rescue => e
    Rails.logger.error(e)
    nil
  end

  ##
  # Lazy load multi-page response.
  # Return empty array if response fails.
  #
  # @return [Array<Google::Apis::AnalyticsV3::GaData>] | empty array
  #
  def multi_page_response
    @multi_page_response ||= Rails.cache.fetch("#{cache_key}:multi", expires_in: 2.hours) do
      events_builder.multi_page_response
    end
  rescue => e
    Rails.logger.error(e)
    Array.new
  end

  private

  ##
  # @return GaResponseBuilder
  # @throws exception if HTTP request fails
  #
  def events_builder
    event_category = "#{@event_name} : #{@hub}"
    filters = %W(ga:eventCategory==#{event_category})
    filters.concat %W(ga:eventAction==#{@contributor}) if @contributor

    GaResponseBuilder.build do |builder|
      builder.profile_id = profile_id
      builder.start_date = @start_date.iso8601
      builder.end_date = @end_date.iso8601
      builder.metrics = %w(ga:totalEvents)
      builder.dimensions = %w(ga:eventLabel ga:eventAction)
      builder.filters = filters
      builder.sort = %w(-ga:totalEvents) # Descending
      builder.page = @page
    end
  end

  def profile_id
    Settings.google_analytics.frontend_profile_id
  end
end
