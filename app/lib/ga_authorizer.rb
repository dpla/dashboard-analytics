require 'googleauth'

##
# Get authorization to access Google Analytics accounts.
# The token can be used for server-side requests, or can be passed to the client
# to authorize client-side requests.
#
# No attempts are not made to re-try failed HTTP requests because the googleauth
# gem lacks good interfaces to manage this.
#
class GaAuthorizer

  ##
  # @return [String|nil]
  # By default, the access token will expire after 1 hour.
  def self.token
    if(self.authorizer.access_token.nil? or self.authorizer.expired?)
      self.authorizer.fetch_access_token!
    end
    self.authorizer.access_token

  rescue StandardError => e
    Rails.logger.error(e)
    # Return nil if an error occurs when attempting to get access token, such
    # as an HTTP error.
    return nil
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
