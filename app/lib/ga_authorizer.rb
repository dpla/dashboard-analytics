require 'googleauth'

class GaAuthorizer

  ##
  # @return [String]
  def self.token
    begin
      # By default, the access token will expire after 1 hour.

      if(self.authorizer.access_token.nil? or self.authorizer.expired?)
        self.authorizer.fetch_access_token!
      end
      self.authorizer.access_token
    rescue
      # TODO: Log error
      String.new
    end
  end

  private

  ##
  # @return Google::Auth::ServiceAccountCredentials
  def self.authorizer
    @@authorizer ||= Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(Settings.google_analytics.service_account_json_key),
      scope: 'https://www.googleapis.com/auth/analytics.readonly')
  end
end
