class WikimediaAnalyticsPresenter

  # Fields to be shown in the user interface.
  def self.fields
    [ 'Upload count', 'Page views' ]
  end

  ##
  # @param [WikimediaAnalytics]
  def initialize(wikimedia_analytics)
    @wikimedia_analytics = wikimedia_analytics
  end

  ##
  # @param [String]
  # @return [Array<CSV::Row>]
  def all_contributors(hub)
    @wikimedia_analytics.wiki_csv
      .find_all { |row| row["Hub"] == hub && row["Institution"] != hub }
  rescue => e
    Rails.logger.error(e)
    Array.new
  end

  ##
  # @param hub [String]
  # @param contributor [String]
  # @return [Hash]
  def contributor(hub, contributor)
    @wikimedia_analytics.wiki_csv
      .find { |row| row["Hub"] == hub && row["Institution"] == contributor }
      .to_hash
  rescue => e
    Rails.logger.error(e)
    Hash.new
  end

  ##
  # @param [String]
  # @return [Hash]
  def hub(hub)
    @wikimedia_analytics.wiki_csv
      .find { |row| row["Hub"] == hub && row["Institution"] == hub }
      .to_hash
  rescue => e
    Rails.logger.error(e)
    Hash.new
  end

  ##
  # @return Date|nil
  def file_date
    @wikimedia_analytics.file_date
  end
end
