# Descriptive names for CSV downloads, e.g.
# "HathiTrust_Exhibition-views_2025-07_2026-07.csv"
module CsvFilenameHelper

  ##
  # Join the parts into a filename.
  # Blank parts drop out, so hub- and contributor-level downloads
  # share one call.
  #
  # @param parts [Array<String, nil>] e.g. hub, contributor, table title
  # @return [String]
  #
  def csv_filename(*parts)
    slugs = parts.flatten.filter_map do |part|
      slug = part.to_s.parameterize(preserve_case: true)
      slug.presence
    end
    "#{slugs.join('_')}.csv"
  end

  # "2025-07_2026-07", or one month when the range is a single month.
  def csv_date_range(start_date = @start_date, end_date = @end_date)
    return nil unless start_date && end_date

    from = start_date.strftime("%Y-%m")
    through = end_date.strftime("%Y-%m")
    from == through ? from : "#{from}_#{through}"
  end
end
