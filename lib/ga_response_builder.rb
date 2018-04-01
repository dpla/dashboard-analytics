require 'google/apis/analytics_v3'
require 'googleauth'

class GaResponseBuilder
  attr_accessor :data

  @@authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open(Settings.google_analytics.service_account_json_key),
    scope: 'https://www.googleapis.com/auth/analytics.readonly')

  def initialize(hub)
    @profile_id = Settings.google_analytics.profile_id
    @hub = hub
    @analytics = Google::Apis::AnalyticsV3::AnalyticsService.new
    @analytics.authorization = token
    @start_date = "2018-03-01"
    @end_date = "2018-03-31"
  end

  def token
    # By default, the access token will expire after 1 hour.
    if(@@authorizer.access_token.nil? or @@authorizer.expired?)
      @@authorizer.fetch_access_token!
    end
    @@authorizer.access_token
  end

  def event_metrics
    dimensions = %w(ga:eventCategory)
    metrics = %w(ga:totalEvents)
    filters = %W(ga:eventCategory=@#{@hub})

    result = @analytics.get_ga_data(@profile_id,
                                    @start_date,
                                    @end_date,
                                    metrics.join(','),
                                    dimensions: dimensions.join(','),
                                    filters: filters.join(','))

    self.data = result

    result.rows.collect{ |r| 
      [r[0].split(' : ')[0].parameterize.underscore.to_sym, r[1]]
    }.to_h
  end
end
