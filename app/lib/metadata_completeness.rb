class MetadataCompleteness
  include ActionView::Helpers::NumberHelper

  ##
  # @return [MetadataCompleteness]
  #
  # @example
  #   MetadataCompleteness.build do |builder|
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

  def hub_csv
    response = sThree_response("provider.csv")
    csv_data(response)
  end

  def contributor_csv
    response = sThree_response("contributor.csv")
    csv_data(response)
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

      # File path in format YYYY/MM/filename.csv
      key = "#{date.year}/#{date.strftime("%m")}/#{file_name}"

      begin
        response = SThreeResponseBuilder.response(key)
      rescue Aws::S3::Errors::NoSuchKey => e
        Rails.logger.debug("#{key} does not exist.")
        # Loop continues
      rescue Exception => e
        Rails.logger.debug(e)
        break
      end

      date = date.last_month
    end

    return response
  end

  ##
  # @param Aws::S3::Types::GetObjectOutput
  # @return CSV
  def csv_data(response)
    # response.body.read is instance of String
    CSV.new(response.body.read, headers: true)
  end

  ##
  # Minimum data that data is expected to be available.
  # @return Date
  def min_date
    Date.new(Settings.mc_min_date.year.to_i, Settings.mc_min_date.month.to_i)
  end
end
