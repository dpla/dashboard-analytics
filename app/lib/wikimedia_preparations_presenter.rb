class WikimediaPreparationsPresenter

  # Fields to be shown in the user interface.
  def self.fields
    [ 'mediaAccess', 'iiifManifest', 'mediaMaster', 'openLicense', 'wikimediaReady' ]
  end

  ##
  # @param [MetadataCompleteness]
  def initialize(metadata_completeness)
    @metadata_completeness = metadata_completeness
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