require 'google/apis/analytics_v3'
require 'googleauth'

class GaResponseBuilder
  attr_accessor :data

  @@authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open(Settings.google_analytics.service_account_json_key),
    scope: 'https://www.googleapis.com/auth/analytics.readonly')

  def initialize
    @profile_id = Settings.google_analytics.profile_id

    start_date = "2018-03-01"
    end_date = "2018-03-31"
    hub = "California Digital Library"

    analytics = Google::Apis::AnalyticsV3::AnalyticsService.new
    analytics.authorization = token

    dimensions = %w(ga:eventCategory)
    metrics = %w(ga:totalEvents)
    filters = %W(ga:eventCategory=@#{hub})
    # sort = %w(ga:date)

    result = analytics.get_ga_data(@profile_id,
                                   start_date,
                                   end_date,
                                   metrics.join(','),
                                   dimensions: dimensions.join(','),
                                   filters: filters.join(',')
                                   # sort: sort.join(',')
                                   )

    data = []
    data.push(result.column_headers.map { |h| h.name })
    data.push(*result.rows)
    self.data = data
  end

  def token
    # By default, the access token will expire after 1 hour.
    if(@@authorizer.access_token.nil? or @@authorizer.expired?)
      @@authorizer.fetch_access_token!
    end
    @@authorizer.access_token
  end
end
