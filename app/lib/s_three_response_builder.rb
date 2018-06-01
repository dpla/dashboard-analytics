class SThreeResponseBuilder

  ##
  # @param start_date [String] in format YYYT-MM-DD (iso8601)
  # @param end_date [String] in format YYYT-MM-DD (iso8601)
  #
  def initialize(end_date)
    @end_date = end_date
  end

  ##
  # @return String
  def month
    # @end_date.split("-")[1]
    "04"
  end

  ##
  # @return String
  def year
    @end_date.split("-").first
  end

  ##
  # @return CSV
  def provider_data
    get_csv("provider.csv")
  end

  ##
  # @return CSV
  def contributor_data
    get_csv("contributor.csv")
  end

  # private

  ##
  # @return Aws::S3::Client
  def client
    @client ||= Aws::S3::Client.new(region: 'us-east-1')
  end

  ##
  # @return String
  def bucket
    "dashboard-analytics"
  end

  # @param String file name
  # @return CSV
  def get_csv(name)
    key = "#{year}/#{month}/#{name}"
    # key = "2018/04/provider.csv"
    # response is instance of Seahorse::Client::Response
    response = client.get_object({ bucket: bucket, key: key })
    # response.body.read is instance of String
    CSV.new(response.body.read, headers: true)
  end
end
