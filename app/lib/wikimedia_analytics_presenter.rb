class WikimediaAnalyticsPresenter

  # Fields to be shown in the user interface.
  def self.fields
    [ 'Upload count', 'Page views', 'Files Used', 'Pages Enhanced' ]
  end

  ##
  # @param start_month [String] "YYYY-MM"
  # @param end_month   [String] "YYYY-MM"
  def initialize(start_month:, end_month:)
    @start_month = start_month
    @end_month   = end_month
  end

  ##
  # @param hub [String]
  # @return [Hash]
  def hub(hub)
    WikimediaCache.totals_for(hub: hub, contributor: "", start_month: @start_month, end_month: @end_month)
  rescue => e
    Rails.logger.error(e)
    {}
  end

  ##
  # @param hub         [String]
  # @param contributor [String]
  # @return [Hash]
  def contributor(hub, contributor)
    WikimediaCache.totals_for(hub: hub, contributor: contributor, start_month: @start_month, end_month: @end_month)
  rescue => e
    Rails.logger.error(e)
    {}
  end

  ##
  # Returns a list of hashes, one per contributor, each containing the
  # contributor's name under 'Institution' plus their aggregated field values.
  # This preserves compatibility with ContributorComparison which does
  # row['Institution'] and row[field] lookups on these objects.
  #
  # @param hub [String]
  # @return [Array<Hash>]
  def all_contributors(hub)
    WikimediaCache
      .where(hub: hub, month: @start_month..@end_month)
      .where.not(contributor: "")
      .group(:contributor)
      .select(:contributor,
              Arel.sql("SUM(page_views) AS page_views"),
              Arel.sql("MAX(upload_count) AS upload_count"),
              Arel.sql("MAX(files_used) AS files_used"),
              Arel.sql("MAX(pages_enhanced) AS pages_enhanced"))
      .map do |row|
        {
          "Institution"    => row.contributor,
          "Page views"     => row.page_views&.to_i     || 0,
          "Upload count"   => row.upload_count&.to_i   || 0,
          "Files Used"     => row.files_used&.to_i     || 0,
          "Pages Enhanced" => row.pages_enhanced&.to_i || 0
        }
      end
  rescue => e
    Rails.logger.error(e)
    []
  end
end
