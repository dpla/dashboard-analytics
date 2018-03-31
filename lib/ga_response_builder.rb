require 'google/apis/analytics_v3'
require 'googleauth'

class GaResponseBuilder
  attr_accessor :data

  @@authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open(Settings.google_analytics.service_account_json_key),
    scope: 'https://www.googleapis.com/auth/analytics.readonly')

  def initialize

    profile_id = Settings.google_analytics.profile_id

    start_date = "2018-01-01"
    end_date = "2018-01-31"

    analytics = Google::Apis::AnalyticsV3::AnalyticsService.new
    analytics.authorization = token

    dimensions = %w(ga:date)
    metrics = %w(ga:sessions ga:users ga:newUsers)
    sort = %w(ga:date)

    result = analytics.get_ga_data(profile_id,
                                   start_date,
                                   end_date,
                                   metrics.join(','),
                                   dimensions: dimensions.join(','),
                                   sort: sort.join(','))

    data = []
    data.push(result.column_headers.map { |h| h.name })
    data.push(*result.rows)
    self.data = data
  end

  def token
    if(@@authorizer.access_token.nil? or @@authorizer.expired?)
      @@authorizer.fetch_access_token!
    end
    @@authorizer.access_token
  end
end
