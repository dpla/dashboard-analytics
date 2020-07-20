class MetadataCompletenessPresenter

  # Fields to be shown in the user interface.
  def self.fields
    [ 'title', 'type', 'subject', 'description', 'preview', 'date', 'creator',
      'spatial', 'language', 'standardizedRights', 'count' ]
  end

  ##
  # @param [MetadataCompleteness]
  def initialize(metadata_completeness)
    @metadata_completeness = metadata_completeness
  end

  ##
  # @param [String]
  # @return [Array<CSV::Row>]
  def all_contributors(hub)
    @metadata_completeness.contributor_csv
      .find_all { |row| row["provider"] == hub }
  rescue => e
    Rails.logger.error(e)
    Array.new
  end

  ##
  # @param hub [String]
  # @param contributor [String]
  # @return [Hash]
  def contributor(hub, contributor)
    @metadata_completeness.contributor_csv
      .find { |row| row["provider"] == hub && row["dataProvider"] == contributor }
      .to_hash
  rescue => e
    Rails.logger.error(e)
    Hash.new
  end

  ##
  # @param [String]
  # @return [Hash]
  def hub(hub)
    @metadata_completeness.hub_csv
      .find { |row| row["provider"] == hub }
      .to_hash
  rescue => e
    Rails.logger.error(e)
    Hash.new
  end

  ##
  # @return Date|nil
  def file_date
    @metadata_completeness.file_date
  end
end
