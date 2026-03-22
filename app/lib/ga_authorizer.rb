require 'googleauth'

##
# Provides Google service account credentials for GA4 API calls.
# Returns a ServiceAccountCredentials object, which the Google API client
# uses to fetch and refresh access tokens automatically.
#
class GaAuthorizer
  def self.credentials
    @@credentials ||= Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(File.read(Settings.google_analytics.service_account_json_key)),
      scope: 'https://www.googleapis.com/auth/analytics.readonly'
    )
  end

  ##
  # Returns an access token string. Used by views that pass GA tokens to
  # client-side JavaScript (timelines, maps, etc.).
  def self.token
    creds = credentials
    creds.fetch_access_token! if creds.access_token.nil? || creds.expired?
    creds.access_token
  rescue => e
    Rails.logger.error(e)
    nil
  end
end
