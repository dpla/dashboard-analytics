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
    @end_date.split("-")[1]
  end

  ##
  # @return String
  def year
    @end_date.split("-").first
  end

  ##
  # @return CSV | nil
  def provider_data
    most_recent("provider.csv")
  end

  ##
  # @return CSV | nil
  def contributor_data
    most_recent("contributor.csv")
  end

  private

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

  def min_date
    Date.new(Settings.mc_min_date.year.to_i, Settings.mc_min_date.month.to_i)
  end

  ##
  # @param String file name
  # @return CSV | nil
  def most_recent(name)
    date = Date.new(year.to_i, month.to_i)
    response = nil

    while response == nil
      break if date < min_date

      # File path in format YYYY/MM/filename.csv
      key = "#{date.year}/#{date.strftime("%m")}/#{name}"

      begin
        puts "try #{key}"
        response = get_csv(key)
      rescue Aws::S3::Errors::NoSuchKey => e
        # no action, loop continues
      rescue Exception => e
        # TODO: log/handle error
      end

      date = date.last_month
    end

    return response
  end

  ##
  # @param String filepath
  # @return CSV
  # @throws Aws::S3::Errors::NoSuchKey if file does not exist
  def get_csv(key)
    # response is instance of Seahorse::Client::Response
    response = client.get_object({ bucket: bucket, key: key })
    # response.body.read is instance of String
    CSV.new(response.body.read, headers: true)
  end
end
