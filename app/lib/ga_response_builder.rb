require 'google/apis/analytics_v3'

class GaResponseBuilder

  ##
  # @return [GaResponseBuilder]
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
    builder
  end

  def initialize
    @analytics = Google::Apis::AnalyticsV3::AnalyticsService.new
    @profile_id = nil
    @start_date = nil
    @end_date = nil
    @metrics = []
    @dimensions = []
    @filters = []
    @start_index = 1
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
  # Authorize the AnalyticsService.
  # If the AnalyticsService is not authorized, any request for data will return
  # an error.
  def authorize
    @analytics.authorization = GaAuthorizer.token
  end

  ##
  # @return [Google::Apis::AnalyticsV3::GaData]
  #
  # @raise [Google::Apis::ServerError]
  # An error occurred on the server and the request can be retried.
  #
  # @raise [Google::Apis::ClientError]
  # The request is invalid and should not be retried without modification.
  #
  # @raise [Google::Apis::AuthorizationError]
  # Authorization is required.
  #
  def response
    tries ||= 0

    @analytics.get_ga_data(@profile_id,
                           @start_date,
                           @end_date,
                           @metrics,
                           dimensions: @dimensions,
                           filters: @filters,
                           sort: @sort,
                           start_index: @start_index,
                           segment: @segment)

  rescue Google::Apis::AuthorizationError
    # Reauthorize in case token has expired or been invalidated.
    authorize and retry unless(tries += 1) == 2
  rescue Google::Apis::ServerError
    # Use exponential backoff to delay next request attempt.
    sleep(2**tries + rand) and retry unless(tries += 1) == 3
  end

  ##
  # @return [Array<Google::Apis::AnalyticsV3::GaData>]
  def multi_page_response
    results = [response]
    more = results.last.next_link.present?

    while more == true
      @start_index = (results.last.query.start_index.to_i + results.last.items_per_page.to_i)
      results.push response
      more = results.last.next_link.present?
    end

    results
  end
end
