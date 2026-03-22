class WikimediaCache < ApplicationRecord
  self.table_name = "wikimedia_cache"

  # Aggregated stats for a hub or contributor over a date range.
  # contributor is "" for hub-level rows.
  #
  # Aggregation rules:
  #   page_views     → SUM
  #   upload_count   → MAX
  #   files_used     → MAX
  #   pages_enhanced → MAX

  def self.totals_for(hub:, contributor: "", start_month:, end_month:)
    scope = where(hub: hub, contributor: contributor)
              .where(month: start_month..end_month)
    scope.pick(
      Arel.sql("SUM(page_views)"),
      Arel.sql("MAX(upload_count)"),
      Arel.sql("MAX(files_used)"),
      Arel.sql("MAX(pages_enhanced)")
    ).then do |pv, uc, fu, pe|
      {
        "Page views"     => pv&.to_i || 0,
        "Upload count"   => uc&.to_i || 0,
        "Files Used"     => fu&.to_i || 0,
        "Pages Enhanced" => pe&.to_i || 0
      }
    end
  end
end
