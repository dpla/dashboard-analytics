class SThreeResponseBuilder

  ##
  # @param file_name [String] e.g. "provider.csv"
  # @param end_date [Date]
  def initialize(file_name, end_date)
    @file_name = file_name
    @end_date = end_date
  end

  ##
  # Get data from the month specified in end_date.
  # If no data is available for that month, get the previous month.
  # Continue trying until data is available or min date is surpassed.
  #
  # @return Seahorse::Client::Response
  def response
    date = @end_date
    response = nil

    while response == nil
      break if date < min_date

      # File path in format YYYY/MM/filename.csv
      key = "#{date.year}/#{date.strftime("%m")}/#{@file_name}"

      Rails.logger.debug("trying #{key}")

      begin
        response = client.get_object({ bucket: bucket, key: key })
      rescue Aws::S3::Errors::NoSuchKey => e
        # no action, loop continues
      rescue Exception => e
        # TODO: log/handle error
      end

      date = date.last_month
    end

    return response
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
    Settings.s3.bucket
  end

  ##
  # Minimum data that data is expected to be available.
  # @return Date
  def min_date
    Date.new(Settings.mc_min_date.year.to_i, Settings.mc_min_date.month.to_i)
  end
end
