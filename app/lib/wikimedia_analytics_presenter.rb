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
    []
  end

  ##
  # @param hub [String]
  # @param contributor [String]
  # @return [Hash]
  def contributor(hub, contributor)
    @wikimedia_analytics.wiki_csv
      .find { |row| row["Hub"] == hub && row["Institution"] == contributor }
      &.to_hash || {}
  rescue => e
    Rails.logger.error(e)
    {}
  end

  ##
  # @param [String]
  # @return [Hash]
  def hub(hub)
    csv = @wikimedia_analytics.wiki_csv
    row = csv.find { |r| r["Hub"] == hub && r["Institution"] == hub }
    return row.to_hash if row

    # No hub-level aggregate row in the CSV — sum contributor rows instead.
    contributors = csv.select { |r| r["Hub"] == hub && r["Institution"] != hub }
    return {} if contributors.empty?

    self.class.fields.each_with_object({}) do |field, hash|
      hash[field] = contributors.sum { |r| r[field].to_i }.to_s
    end
  rescue => e
    Rails.logger.error(e)
    {}
  end

  ##
  # @return Date|nil
  def file_date
    @wikimedia_analytics.file_date
  end
end
