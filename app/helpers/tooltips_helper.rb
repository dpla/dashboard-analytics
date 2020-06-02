module TooltipsHelper

  # DPLA Website

  def website_use_tooltip
    "Use of your items on the DPLA website."
  end

  def view_item_tooltip
    "One of your items was viewed in any of the DPLA website's engagement points,
    including the digital library catalog, exhibitions, and primary source sets.
    Comparable to \"pageview\" in Google Analytics."
  end

  def view_metadata_record_tooltip
    "A record for your item was viewed in the digital library catalog.
    Users usually find these records by searching or browsing the catalog.
    Comparable to \"pageview\" in Google Analytics."
  end

  def view_exhibition_tooltip
    "One of your items was viewed within a curated DPLA exhibition.
    Comparable to \"pageview\" in Google Analytics."
  end

  def view_primary_source_set_tooltip
    "One of your items was viewed within a curated DPLA primary source set.
    Comparable to \"pageview\" in Google Analytics."
  end

  def click_through_tooltip
    "A user clicked on a link to view a full item on your website or your contributor’s website.
    Click through links appear in the digital library catalog and curated content.
    Comparable to \"referral\" in Google Analytics."
  end

  def users_tooltip
    "A user who viewed or clicked through at least one of your items on the DPLA website.
    Equivalent to \"user\" in Google Analytics."
  end

  def sessions_tooltip
    "A visit to the DPLA website that included a view or click through of at least one of your items.
    Equivalent to \"session\" in Google Analytics."
  end

  def timelines_tooltip
    "Use is shown by month.  Adjust the start and end dates above.
    You may see seasonal fluctuations aligned with the academic calendar."
  end

  def user_location_tooltip
    "Locations of users who viewed or clicked through at least one of your items on the DPLA website.
    Equivalent to \"location\" or \"geo network\" in Google Analytics."
  end

  # DPLA API

  def api_use_tooltip
    "Interactions with you item metadata through the DPLA API,
    for use in third-party applications or research."
  end

  def view_api_item_tooltip
    "Metadata from one of your items was included in a DPLA API response."
  end

  def api_users_tooltip
    "A third-party user or application that accessed metadata for at least one of your items.
    Note: even if a third-party application has many end-users,
    only the app itself is counted as a single user."
  end

  # Metadata quality

  def item_count_tooltip
    "The number of items you have indexed in DPLA,
    based on the most recent snapshot for the given time period."
  end

  def metadata_completeness_tooltip
    "For each field, the percentage of all your metadata records that have a non-null value for that field.
    These fields are used most heavily in our search and discovery systems,
    and therefore a higher percentage of completeness can lead to more use."
  end

  def media_access_tooltip
    "If a document has mediaAccess, that means that it has either a IIIF manifest
    or full-frame media file(s)."
  end

  def find_tooltip(key)
    case key
    when "view_item"
      view_metadata_record_tooltip
    when "view_exhibit"
      view_exhibition_tooltip
    when "view_pss"
      view_primary_source_set_tooltip
    when "click_through"
      click_through_tooltip
    when "view_api"
      view_api_item_tooltip
    end
  end
end
