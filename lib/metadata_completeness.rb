class MetadataCompleteness
  include ActionView::Helpers::NumberHelper

  # @param Hub || Contributor
  def initialize(target)
    @target = target
  end

  def target
    @target
  end

  # @return Hash
  def data
    @data ||= get_data
  end

  # @param field String the metadata field e.g. "type"
  # @return String percentage representation of completeness for given field
  def percentage(field)
    number_to_percentage(data[field].to_f * 100, precision: 0)
  end

  private

  ##
  # Gets completeness data for the target.
  # @return Hash
  def get_data
    if target.is_a?(Hub)
      get_hub_data
    elsif target.is_a?(Contributor)
      get_contributor_data
    end
  end

  # @return Hash
  def get_hub_data
    hub_name = target.name rescue nil
    data = nil

    begin
      CSV.foreach(hub_filepath, headers: true) do |row|
        break if data != nil
        data = row if row["provider"] == hub_name
      end
    rescue => e
      # TODO: log error
    end

    return {} if data == nil
    return data.to_hash
  end

  # @return Hash
  def get_contributor_data
    contributor_name = target.name rescue nil
    hub_name = @target.hub.name rescue nil
    data = nil

    begin
      CSV.foreach(contributor_filepath, headers: true) do |row|
        break if data != nil
        if row["provider"] == hub_name and row["dataProvider"] == contributor_name
          data = row
        end
      end
    rescue => e
      # TODO: Log error
    end

    return {} if data == nil
    return data.to_hash
  end

  # @return String
  def hub_filepath
    Rails.root.join("public", "spreadsheets", "provider-scores-20180504.csv")
  end

  # @return String
  def contributor_filepath
    Rails.root.join("public", "spreadsheets", "contributor-scores-20180504.csv")
  end
end
