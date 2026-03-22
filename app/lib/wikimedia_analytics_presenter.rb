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
    csv          = @wikimedia_analytics.wiki_csv
    hub_row      = csv.find   { |r| r["Hub"] == hub && r["Institution"] == hub }
    contributors = csv.select { |r| r["Hub"] == hub && r["Institution"] != hub }

    return {} if hub_row.nil? && contributors.empty?

    # Hub-level rows sometimes have 0 for fields that contributors show as
    # non-zero (a data quality issue in the CSV). Take the max of the hub row
    # value and the contributor sum per field so neither source is silently lost.
    self.class.fields.each_with_object({}) do |field, hash|
      hub_val    = hub_row ? hub_row[field].to_i : 0
      contrib_sum = contributors.sum { |r| r[field].to_i }
      hash[field] = [hub_val, contrib_sum].max.to_s
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
