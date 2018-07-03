class MetadataCompletenessPresenter

  # Fields to be shown in the user interface.
  def self.fields
    [ 'type', 'subject', 'description', 'preview', 'date', 'creator',
      'location', 'language', 'standardizedRights', 'count' ]
  end

  ##
  # @param [MetadataCompleteness]
  def initialize(metadata_completeness)
    @metadata_completeness = metadata_completeness
  end

  ##
  # @param [String]
  # @return [Array]
  def all_contributors(hub)
    @metadata_completeness.contributor_csv
      .find_all { |row| row["provider"] == hub }
  end

  ##
  # @param [String]
  # @return [Hash]
  def contributor(hub, contributor)
    @metadata_completeness.contributor_csv
      .find { |row| row["provider"] == hub && row["dataProvider"] == contributor }
      .to_hash
      .select { |k, v| self.class.fields.include? k }
  end

  ##
  # @param [String]
  # @return [Hash]
  def hub(hub)
    @metadata_completeness.hub_csv
      .find { |row| row["provider"] == hub }
      .to_hash
      .select { |k| self.class.fields.include? k }
  end
end
