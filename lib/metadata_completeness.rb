class MetadataCompleteness
  include ActionView::Helpers::NumberHelper

  # Fields to be shown in the user interface.
  def self.fields
    [ 'type', 'subject', 'description', 'preview', 'date',  'creator',
      'location', 'language' ]
  end

  # @param Hub || Contributor
  def initialize(target)
    @target = target
  end

  def target
    @target
  end

  # @return Hash
  def data
    @data ||= get_data.select { |k, v| self.class.fields.include? k }
  end

  def hub_name
    target.is_a?(Hub) ? target.name : target.hub.name
  end

  def contributor_name
    target.is_a?(Contributor) ? target.name : nil
  end

  def all_contributors_data
    @all_contributors_data ||= get_all_contributors_data
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

  # @return Array[Hash]
  def get_all_contributors_data
    data = []

    begin
      CSV.foreach(contributor_filepath, headers: true) do |row|
        if row["provider"] == hub_name
          data.push(row.to_hash)
        end
      end
    rescue => e
      # TODO: Log error
    end

    return data
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
