require 'google/apis/analytics_v3'
require 'googleauth'

class GaResponseBuilder

  ##
  # @return [Google::Apis::AnalyticsV3::GaData]
  #
  # @example
  #   GaResponseBuilder.build do |builder|
  #     builder.profile_id = 'ga:123'
  #     builder.start_date = '2018-01=01'
  #     builder.end_date = '2018-01-31'
  #     builder.metrics = ['ga:users']
  #   end
  #
  def self.build
    builder = new
    yield(builder)
    builder.authorize
    builder.response
  end

  def initialize
    @analytics = Google::Apis::AnalyticsV3::AnalyticsService.new
    @profile_id = nil
    @start_date = nil
    @end_date = nil
    @metrics = []
    @dimensions = []
    @filters = []
    @start_index = nil
    @sort = nil
    @segment = nil
  end

  # @param [String]
  # Required
  def profile_id=(profile_id)
    @profile_id = profile_id
  end

  # @param [String] in format YYYT-MM-DD (iso8601)
  # Required
  def start_date=(start_date)
    @start_date = start_date
  end

  # @param [String] in format YYYT-MM-DD (iso8601)
  # Required
  def end_date=(end_date)
    @end_date = end_date
  end

  # @param [Array<String>]
  # Required
  def metrics=(metrics)
    @metrics = metrics.join(',') #comma = "or"
  end

  # @param [Array<String>]
  def dimensions=(dimensions)
    @dimensions = dimensions.join(',') #comma = "or"
  end

  # @param [Array<String>]
  def filters=(filters)
    @filters = filters.join(';') #semicolon = "and"
  end

  # @param [String | Int] ???
  def start_index=(start_index)
    @start_index = start_index
  end

  # @param [String]
  def sort=(sort)
    @sort = sort
  end

  # @param [String]
  def segment=(segment)
    @segment = segment
  end

  ##
  # @return [Google::Apis::AnalyticsV3::GaData]
  #
  # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
  # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
  # @raise [Google::Apis::AuthorizationError] Authorization is required
  # 
  # TODO: Retry failed request if appropriate
  def response
    tries ||= 3
    @analytics.get_ga_data(@profile_id,
                           @start_date,
                           @end_date,
                           @metrics,
                           dimensions: @dimensions,
                           filters: @filters,
                           sort: @sort,
                           start_index: @start_index,
                           segment: @segment)

  rescue Exception => e
    retry unless(tries -= 1).zero?
  end

  ##
  # Authorize the AnalyticsService.
  # If the AnalyticsService is not authorized, any request for data will return
  # an error.
  def authorize
    @analytics.authorization = GaAuthorizer.token
  end
end
