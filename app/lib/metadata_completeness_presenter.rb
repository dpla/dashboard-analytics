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
  # @return [Array<CSV::Row>]
  def all_contributors(hub)
    @metadata_completeness.contributor_csv
      .find_all { |row| row["provider"] == hub }
  end

  ##
  # @param hub [String]
  # @param contributor [String]
  # @return [CSV::Row]
  def contributor(hub, contributor)
    @metadata_completeness.contributor_csv
      .find { |row| row["provider"] == hub && row["dataProvider"] == contributor }
  end

  ##
  # @param [String]
  # @return [CSV::Row]
  def hub(hub)
    @metadata_completeness.hub_csv.find { |row| row["provider"] == hub }
  end
end
