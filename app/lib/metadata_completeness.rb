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

  private

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

    begin
      sThree.provider_data.each do |row|
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

    begin
      sThree.contributor_data.each do |row|
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

    begin
      sThree.contributor_data.each do |row|
        if row["provider"] == @hub
          data.push(row.to_hash)
        end
      end
    rescue => e
      # TODO: Log error
    end

    return data
  end

  def sThree
    SThreeResponseBuilder.new(@end_date.iso8601)
  end
end
