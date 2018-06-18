require 'google/apis/analytics_v3'
require 'googleauth'

class GaResponseBuilder

  ##
  # @param start_date [String] in format YYYT-MM-DD (iso8601)
  # @param end_date [String] in format YYYT-MM-DD (iso8601)
  #
  # def initialize(start_date, end_date)
  #   @start_date = start_date
  #   @end_date = end_date
  # end

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
    @metrics = nil
    @dimensions = nil
    @filters = nil
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
  # @return [String]
  #
  # def token
  #   begin
  #     # By default, the access token will expire after 1 hour.
  #     if(self.class.authorizer.access_token.nil? or self.class.authorizer.expired?)
  #       self.class.authorizer.fetch_access_token!
  #     end
  #     self.class.authorizer.access_token
  #   rescue
  #     # TODO: Log error
  #     String.new
  #   end
  # end

  ##
  # @return Hash
  #   Example search_terms.results:
  #     [["genealogy", "140"], ["\"family bible\"", "65"] ... ]
  # def search_terms(start_index = nil)
  #   metrics = %w(ga:searchUniques)
  #   dimensions = %w(ga:searchKeyword)
  #   filters = nil
  #   sort = %w(-ga:searchUniques) # Descending

  #   options={ sort: sort, start_index: start_index }

  #   begin
  #     res = response(metrics, dimensions, filters, options=options )

  #     { items_per_page: res.items_per_page,
  #       start_index: res.query.start_index,
  #       total_results: res.total_results,
  #       next_link: res.next_link,
  #       results: res.rows }
  #   rescue => e
  #     Rails.logger.error(e)
  #     Hash.new
  #   end
  # end

  ##
  # Get all search terms. Paginate as necessary.
  # @return [Array]
  # def all_search_terms
  #   results = [search_terms]
  #   more = search_terms[:next_link].present?

  #   while more == true
  #     next_start_index = results.last[:start_index] + results.last[:items_per_page]
  #     results.push search_terms(next_start_index)
  #     more = results.last[:next_link].present?
  #   end
    
  #   results.flat_map { |response| response[:results] }
  # end

  # protected

  ##
  # Abstract method - must be implemented in subclasses.
  # def profile_id
  #   raise NotImplementedError
  # end

  ##
  # Can be overwritten in subclass.
  # def segment
  # end

  ##
  # @return Google::Auth::ServiceAccountCredentials
  # def self.authorizer
  #   @@authorizer ||= Google::Auth::ServiceAccountCredentials.make_creds(
  #     json_key_io: File.open(Settings.google_analytics.service_account_json_key),
  #     scope: 'https://www.googleapis.com/auth/analytics.readonly')
  # end

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
  # def response(metrics, dimensions, filters, options={})
  #   # TODO max results
  #   sort = options[:sort]
  #   start_index = options[:start_index]

  #   #semicolon = "and"
  #   filters = filters.present? ? filters.join(';') : nil

  #   analytics.get_ga_data(profile_id,
  #                         start_date,
  #                         end_date,
  #                         metrics.join(','), #comma = "or"
  #                         dimensions: dimensions.join(','), #comma = "or"
  #                         filters: filters,
  #                         sort: sort,
  #                         start_index: start_index,
  #                         segment: segment) 
  # end

  # @return [Google::Apis::AnalyticsV3::GaData]
  def response
    @analytics.get_ga_data(@profile_id,
                           @start_date,
                           @end_date,
                           @metrics,
                           dimensions: @dimensions,
                           filters: @filters,
                           sort: @sort,
                           start_index: @start_index,
                           segment: @segment) 
  end

  def authorize
    @analytics.authorization = GaAuthorizer.token
  end

  # def analytics
  #   @analytics ||= Google::Apis::AnalyticsV3::AnalyticsService.new
  #   @analytics.authorization = token
  #   @analytics
  # end
end
