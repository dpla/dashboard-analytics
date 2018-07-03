class MetadataCompleteness
  include ActionView::Helpers::NumberHelper

  # Fields to be shown in the user interface.
  def self.fields
    [ 'type', 'subject', 'description', 'preview', 'date', 'creator',
      'location', 'language', 'standardizedRights' ]
  end

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

  # @return Hash
  def data
    @data ||= get_data
  end

  # @return Hash
  def field_data
    data.select { |k, v| self.class.fields.include? k }
  end

  def count
    data['count']
  end

  def all_contributors_data
    @all_contributors_data ||= get_all_contributors_data
  end

  # private

  ##
  # Gets completeness data for the target.
  # @return Hash
  def get_data
    if @contributor.present?
      get_contributor_data
    elsif @hub.present?
      get_hub_data
    end
  end

  # @return Hash
  def get_hub_data
    data = nil
    response = sThree_response("provider.csv")
    csv = csv_data(response)

    begin
      csv.each do |row|
        break if data != nil
        data = row if row["provider"] == @hub
      end
    rescue => e
      # TODO: log error
    end

    return {} if data == nil
    return data.to_hash
  end

  # @return Hash
  def get_contributor_data
    data = nil
    response = sThree_response("contributor.csv")
    csv = csv_data(response)

    begin
      csv.each do |row|
        break if data != nil
        if row["provider"] == @hub and row["dataProvider"] == @contributor
          data = row
        end
      end
    rescue => e
      # TODO: Log error
    end

    return {} if data == nil
    return data.to_hash
  end

  # @return Array[Hash]
  def get_all_contributors_data
    data = []
    response = sThree_response("contributor.csv")
    csv = csv_data(response)

    begin
      csv.each do |row|
        if row["provider"] == @hub
          data.push(row.to_hash)
        end
      end
    rescue => e
      # TODO: Log error
    end

    return data
  end

  ##
  # Get data from the month specified in end_date.
  # If no data is available for that month, get the previous month.
  # Continue trying until data is available or min date is surpassed.
  #
  # @return Seahorse::Client::Response
  def sThree_response(file_name)
    date = @end_date
    response = nil

    while response == nil
      break if date < min_date

      # File path in format YYYY/MM/filename.csv
      key = "#{date.year}/#{date.strftime("%m")}/#{file_name}"

      begin
        response = s_three.response(key)
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

  def s_three
    @s_three ||= SThreeResponseBuilder.new
  end

  ##
  # @param Seahorse::Client::Response
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
