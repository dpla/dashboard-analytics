require 'csv'

class WebsiteEventsPresenter  < GaResponsePresenter

  MEMBERSHIP_KINDS = {
    "View Exhibition Item" => :exhibitions,
    "View Primary Source" => :primary_source_sets,
  }.freeze

  def label
    dict = {
      "View Item" => "Digital library catalog views",
      "View Exhibition Item" => "Exhibition views",
      "View Primary Source" => "Primary source set views",
      "Click Through" => "DPLA website click throughs"
    }

    dict.key?(@ga_response.event_name) ? dict[@ga_response.event_name] :
      @ga_response.event_name
  end

  def action
    @ga_response.event_name == "Click Through" ? "Click throughs" : "Views"
  end

  def contributor(row, lookup = item_contributor_lookup)
    lookup[id(row)] || row[columns.index("ga:eventAction")]
  end

  def count(row)
    row[columns.index("ga:totalEvents")]
  end

  # nil unless this table shows curated content.
  def membership_kind
    MEMBERSHIP_KINDS[@ga_response.event_name]
  end

  ##
  # Curated-content slugs for the row's item, e.g. ["erie-canal"].
  # Empty for other tables, which never hit the API.
  #
  def memberships(row)
    return [] unless membership_kind

    membership_lookup[id(row)] || []
  end

  ##
  # Generate CSV of all events
  # @return [CSV]
  def to_csv
    attributes = ["Item", "Item ID", "Contributor", label]
    attributes << membership_column if membership_kind

    CSV.generate(headers: true) do |csv|
      csv << attributes

      multi_page_response.each do |response|
        # Look up names per export page; item_contributor_lookup only covers
        # the displayed page.
        lookup = contributor_lookup(response.rows)

        response.rows.each do |row|
          line = [title(row), id(row), contributor(row, lookup), count(row)]
          line << memberships(row).join("; ") if membership_kind
          csv << line
        end
      end
    end
  end

  def membership_column
    membership_kind == :exhibitions ? "Exhibitions" : "Primary source sets"
  end

  private

  # dataProvider names for the given rows, keyed by item ID, from the S3
  # cache; callers fall back to eventAction (40-char truncated) for the
  # rest.
  # event_label is only queryable from Jul 18, 2025 (registration date;
  # retention doesn't limit Data API reports), so the rebuild can never
  # cover older months.
  def contributor_lookup(page_rows)
    item_ids = page_rows.filter_map { |row| id(row) }.uniq
    resolved = data_providers.slice(*item_ids)
    missing = item_ids - resolved.keys
    return resolved if missing.empty?

    resolved.merge(DplaApiResponseBuilder.new.data_providers_for_items(missing))
  end

  # Memoized: a CSV export reads the mapping once, not per page.
  def data_providers
    @data_providers ||= ItemDataProviders.items
  end

  def item_contributor_lookup
    @item_contributor_lookup ||= contributor_lookup(rows)
  end

  # One lookup for the institution.
  # Serves the displayed page and a full CSV export alike.
  def membership_lookup
    @membership_lookup ||= DplaApiResponseBuilder.new.curated_memberships(
      membership_kind, @ga_response.hub, @ga_response.contributor)
  end
end
