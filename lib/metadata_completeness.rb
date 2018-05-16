require 'open-uri'

class MetadataCompleteness
  include ActionView::Helpers::NumberHelper

  def initialize(target)
    @target = target
  end

  def data
    @data ||= get_data
  end

  def percentage(field)
    number_to_percentage(data[field].to_f * 100, precision: 0)
  end

  private

  def get_data
    if @target.is_a?(Hub)
      get_hub_data
    elsif @target.is_a?(Contributor)
      get_contributor_data
    end
  end

  # @return Hash
  def get_hub_data
    hub_name = @target.name rescue nil
    data = nil

    CSV.foreach(hub_filepath, headers: true) do |row|
      break if data != nil
      data = row if row["provider"] == hub_name
    end

    return {} if data == nil
    return data.to_hash
  end

  def get_contributor_data
    contributor_name = @target.name rescue nil
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

  def hub_filepath
    "/Users/audreyaltman/Desktop/provider-scores-20180504.csv"
  end

  def contributor_filepath
    "/Users/audreyaltman/Desktop/contributor-scores-20180504.csv"
  end
end
