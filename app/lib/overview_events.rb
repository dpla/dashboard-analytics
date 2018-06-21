##
# Event totals for website.
#
class OverviewEvents

  def initialize(target)
    @target = target
    @start_date = target.start_date #already in iso8601
    @end_date = target.end_date #already in iso8601
  end

  def target
    @target
  end

  def hub_name
    target.is_a?(Hub) ? target.name : target.hub.name
  end

  def contributor_name
    target.is_a?(Contributor) ? target.name : nil
  end

  def view_events
    item_events + exhibit_events + pss_events
  end

  def item_events
    parse_response['View Item'].to_i rescue 0
  end

  def exhibit_events
    parse_response['View Exhibition Item'].to_i rescue 0
  end

  def pss_events
    parse_response['View Primary Source'].to_i rescue 0
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
    filters = %W(ga:eventCategory=@#{hub_name} ga:eventCategory!@Browse)
    filters.concat %W(ga:eventAction==#{contributor_name}) if contributor_name

    GaResponseBuilder.build do |builder|
      builder.profile_id = profile_id
      builder.start_date = @start_date
      builder.end_date = @end_date
      builder.metrics = %w(ga:totalEvents)
      builder.dimensions = %w(ga:eventCategory)
      builder.filters = filters
    end
  end

  def parse_response
    if response.present?
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
    Settings.google_analytics.frontend_profile_id
  end
end
