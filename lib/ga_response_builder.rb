require 'google/apis/analytics_v3'
require 'googleauth'

class GaResponseBuilder

  @@authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open(Settings.google_analytics.service_account_json_key),
    scope: 'https://www.googleapis.com/auth/analytics.readonly')

  PROFILE_ID = Settings.google_analytics.profile_id

  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
    @analytics = Google::Apis::AnalyticsV3::AnalyticsService.new
    @analytics.authorization = token
  end

  ##
  # @return [String]
  #
  def token
    # By default, the access token will expire after 1 hour.
    if(@@authorizer.access_token.nil? or @@authorizer.expired?)
      @@authorizer.fetch_access_token!
    end
    @@authorizer.access_token
  end

  ##
  # @param [String] Hub name
  # @return [Hash]
  #
  def hub_overall_use_totals(hub)
    metrics = %w(ga:totalEvents ga:uniqueEvents ga:sessions ga:users)
    dimensions = %w()
    filters = %W(ga:eventCategory=@#{hub} ga:eventCategory!@Browse)

    begin
      response(metrics, dimensions, filters).totals_for_all_results
    rescue
      # TODO: Log error
      Hash.new
    end
  end

  ##
  # @param [String] Hub name
  # @return [Hash]
  #
  def hub_event_totals(hub)
    metrics = %w(ga:totalEvents)
    dimensions = %w(ga:eventCategory)
    filters = %W(ga:eventCategory=@#{hub} ga:eventCategory!@Browse)

    begin
      response(metrics, dimensions, filters).rows.collect{ |row| 
        # Create human-readable key-value pairs
        # Example: change "Click Through : ArtStor" to "Click Through"
        [row[0].split(' : ')[0], row[1]]
      }.to_h
    rescue
      # TODO: Log error message
      Hash.new
    end
  end

  ##
  # @param [String] Hub name
  # @return [Hash]
  #
  def contributor_overall_use_totals(contributor, hub)
    metrics = %w(ga:totalEvents ga:uniqueEvents ga:sessions ga:users)
    dimensions = %w()
    filters = %W(ga:eventAction=@#{contributor} ga:eventCategory=@#{hub} ga:eventCategory!@Browse)

    begin
      response(metrics, dimensions, filters).totals_for_all_results
    rescue
      # TODO: Log error
      Hash.new
    end
  end

  ##
  # @param [String] Hub name
  # @return [Hash]
  #
  def contributor_event_totals(contributor, hub)
    metrics = %w(ga:totalEvents)
    dimensions = %w(ga:eventCategory)
    filters = %W(ga:eventAction=@#{contributor} ga:eventCategory=@#{hub} ga:eventCategory!@Browse)

    begin
      response(metrics, dimensions, filters).rows.collect{ |row| 
        # Create human-readable key-value pairs
        # Example: change "Click Through : ArtStor" to "Click Through"
        [row[0].split(' : ')[0], row[1]]
      }.to_h
    rescue
      # TODO: Log error message
      Hash.new
    end
  end

  ##
  # Get result for a google analytics query.
  #
  # @param metrics [Array<String>]
  # @param dimensions [Array<String>]
  # @param filters [Array<String>]
  #
  # @return [Google::Apis::AnalyticsV3::GaData]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  #
  # TODO: Retry failed request if appropriate?
  #
  def response(metrics, dimensions, filters)
    @analytics.get_ga_data(PROFILE_ID,
                           @start_date,
                           @end_date,
                           metrics.join(','), #comma = "or"
                           dimensions: dimensions.join(','), #comma = "or"
                           filters: filters.join(';')) #semicolon = "and"
  end
end
