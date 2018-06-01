class SThreeResponseBuilder

  ##
  # @param start_date [String] in format YYYT-MM-DD (iso8601)
  # @param end_date [String] in format YYYT-MM-DD (iso8601)
  #
  def initialize(end_date)
    @end_date = end_date
  end

  def month
    # @end_date.split("-")[1]
    "04"
  end

  def year
    @end_date.split("-").first
  end

  def provider_data
    get_csv("provider.csv")
  end

  def contributor_data
    get_csv("contributor.csv")
  end

  private

  # @param String file name
  # @return String representation of the contents of the CSV file
  def get_csv(name)
    client = Aws::S3::Client.new(region: 'us-east-1')
    bucket = "dashboard-analytics"
    key = "#{year}/#{month}/#{name}"
    # key = "2018/04/provider.csv"
    # response is instance of Seahorse::Client::Response
    response = client.get_object({ bucket: bucket, key: key })
    # response.body.read is instance of String
    CSV.new(response.body.read, headers: true)
    # response.body.read
  end
end
