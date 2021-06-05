class WikimediaAnalytics
  include ActionView::Helpers::NumberHelper

  ##
  # @return [WikimediaAnalytics]
  #
  # @example
  #   WikimediaAnalytics.build do |builder|
  #     builder.hub = "California Digital Library"
  #     builder.contributor = "Agua Caliente Cultural Museum"
  #     builder.end_date = Date.today
  #   end
  #
  def self.build
    builder = new
    yield(builder)
    builder
  end

  def initialize
    @hub = nil
    @contributor = nil
    @end_date = nil
    @file_date = nil
  end

  def hub=(hub)
    @hub = hub
  end

  def contributor=(contributor)
    @contributor = contributor
  end

  def end_date=(end_date)
    @end_date = end_date
  end

  def wiki_csv
    response = sThree_response("dpla_stats.csv")
    csv_data(response)
  end

  def file_date
    @file_date
  end

  ##
  # Get data from the month specified in end_date.
  # If no data is available for that month, get the previous month.
  # Continue trying until data is available or min date is surpassed.
  #
  # @return Aws::S3::Types::GetObjectOutput
  #
  def sThree_response(file_name)
    date = @end_date
    response = nil

    while response == nil
      break if date < min_date

      # File path in format wikimedia/YYYY/MM/filename.csv
      prefix = "wikimedia/#{date.year}/#{date.strftime("%m")}/#{file_name}"
      key = nil

      begin
        csv_files = SThreeResponseBuilder.list(prefix).contents
          .select{ |c| c.key.ends_with?(".csv") }
        key = csv_files.first.key unless csv_files.empty?
      rescue Exception => e
        Rails.logger.debug(e)
        break
      end

      if key
        begin
          response = SThreeResponseBuilder.response(key)
        rescue Aws::S3::Errors::NoSuchKey => e
          Rails.logger.debug("#{key} does not exist.")
          # Loop continues
        rescue Exception => e
          Rails.logger.debug(e)
          break
        end
      end

      date = date.last_month
    end

    # set @file_date to the date for which a file was found in AWS
    @file_date = date
    return response
  end

  ##
  # @param Aws::S3::Types::GetObjectOutput
  # @return CSV
  def csv_data(response)
    # response.body.read is instance of String
    # strip all \" from the body of the CSV to avoid parsing error
    CSV.new(response.body.read.gsub('\\"', ''), headers: true, :col_sep => "\t")
  end

  ##
  # Minimum data that data is expected to be available.
  # @return Date
  def min_date
    Date.new(Settings.mc_min_date.year.to_i, Settings.mc_min_date.month.to_i)
  end
end
