class BwsEventTotals

  ##
  # @return [BwsEventTotals]
  #
  # @example
  #   BwsEventTotals.build do |builder|
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
    parse_response['View Item'].to_i rescue 0
  end

  def click_throughs
    parse_response['Click Through'] || 0
  end

  ##
  # Lazy load single-page response.
  # Return nil if response fails.
  #
  # @return [Google::Apis::AnalyticsV3::GaData] | nil
  #
  def response
    @reponse ||= event_overview_builder.response
  rescue => e
    Rails.logger.error(e)
    nil
  end

  private

  ##
  # @return GaResponseBuilder
  # @throws exception if HTTP request fails
  #
  def event_overview_builder
    filters = %W(ga:eventCategory=@#{@hub})
    filters.concat %W(ga:eventAction==#{@contributor}) if @contributor

    GaResponseBuilder.build do |builder|
      builder.profile_id = profile_id
      builder.start_date = @start_date.iso8601
      builder.end_date = @end_date.iso8601
      builder.metrics = %w(ga:totalEvents)
      builder.dimensions = %w(ga:eventCategory)
      builder.filters = filters
    end
  end

  def parse_response
    if response.present? && response.rows.present?
      response.rows.collect{ |row| 
        # Create human-readable key-value pairs
        # Example: change "Click Through : ArtStor" to "Click Through"
        [row[0].split(' : ')[0], row[1]]
      }.to_h
    else
      Hash.new
    end
  end

  def profile_id
    Settings.google_analytics.bws_profile_id
  end
end
