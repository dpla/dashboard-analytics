require 'google/apis/analytics_v3'
require 'googleauth'

class GaResponseBuilder

  @@authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open(Settings.google_analytics.service_account_json_key),
    scope: 'https://www.googleapis.com/auth/analytics.readonly')

  def initialize(hub, start_date, end_date)
    @profile_id = Settings.google_analytics.profile_id
    @hub = hub
    @start_date = start_date
    @end_date = end_date
    @analytics = Google::Apis::AnalyticsV3::AnalyticsService.new
    @analytics.authorization = token
  end

  ##
  # @return [String]
  def token
    # By default, the access token will expire after 1 hour.
    if(@@authorizer.access_token.nil? or @@authorizer.expired?)
      @@authorizer.fetch_access_token!
    end
    @@authorizer.access_token
  end

  ##
  # @return [Hash]
  def overall_metrics
    metrics = %w(ga:totalEvents ga:uniqueEvents ga:sessions ga:users)
    dimensions = %w()
    filters = %W(ga:eventCategory=@#{@hub} ga:eventCategory!@Browse)

    r = result(metrics, dimensions, filters)

    # Create human-readable key-value pairs
    # Example: change "ga:totalEvents" to "Total Events"
    r.totals_for_all_results.map do |key, value| 
      [key.split(':')[1].underscore.humanize.titleize, value]
    end.to_h
  end

  ##
  # @return [Hash]
  def event_metrics
    metrics = %w(ga:totalEvents)
    dimensions = %w(ga:eventCategory)
    filters = %W(ga:eventCategory=@#{@hub} ga:eventCategory!@Browse)

    r = result(metrics, dimensions, filters)

    # Create human-readable key-value pairs
    # Example: change "Click Through : ArtStor" to "Click Through"
    r.rows.collect{ |row| 
      [row[0].split(' : ')[0], row[1]]
    }.to_h
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
  # TODO: handle failed request
  def result(metrics, dimensions, filters)
    @analytics.get_ga_data(@profile_id,
                           @start_date,
                           @end_date,
                           metrics.join(','), #comma = "or"
                           dimensions: dimensions.join(','), #comma = "or"
                           filters: filters.join(';')) #semicolon = "and"
  end
end
