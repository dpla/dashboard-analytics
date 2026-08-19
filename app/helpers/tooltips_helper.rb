module TooltipsHelper

  # DPLA Website

  def website_use_tooltip
    "Use of your items on the DPLA website (dp.la)."
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
    "A user viewed one of your items in a DPLA exhibition.
    Comparable to \"pageview\" in Google Analytics."
  end

  def view_primary_source_set_tooltip
    "A user viewed one of your items in a DPLA primary source set.
    Comparable to \"pageview\" in Google Analytics."
  end

  def click_through_tooltip
    "A user clicked on a link to view a full item on your website or your contributor’s website.
    Click through links appear in the digital library catalog and curated content.
    Comparable to \"referral\" in Google Analytics."
  end

  def users_tooltip
    "A user who viewed or clicked through at least one of your items on the website.
    Equivalent to \"user\" in Google Analytics."
  end

  def sessions_tooltip
    "A visit to the website that included a view or click through of at least one of your items.
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

  # BWS

  def bws_use_tooltip
    "Use of your items on the Black Women's Suffrage website (blackwomenssuffrage.dp.la)."
  end

  def view_bws_item_tooltip
    "One of your items was viewed on the Black Women's Suffrage website.
    Comparable to \"pageview\" in Google Analytics."
  end

  def bws_item_count_tooltip
    "The total number of items you currently have in the Black Women's Suffrage collection.
    Items for the Black Women's Suffrage collection are selected algorithmically
    from the DPLA index."
  end

  # Metadata quality

  def item_count_tooltip
    "The total number of items you currently have indexed in DPLA.
    This is the number of items available in the DPLA Website (dp.la)
    and the DPLA API."
  end

  def metadata_completeness_tooltip
    "For each field, the percentage of all your metadata records that have a non-null value for that field.
    These fields are used most heavily in our search and discovery systems,
    and therefore a higher percentage of completeness can lead to more use."
  end

  def media_access_tooltip
    "If an item has Media Access, that means that it has either a IIIF manifest
    or full-frame media file(s)."
  end

  def wikimedia_readiness_tooltip
    "The number of items eligible for upload into Wikimedia.  These items
    have both media access and open rights."
  end

  def wikimedia_readiness_count_tooltip(count)
    "Approximately #{number_with_delimiter(count, delimiter: ',')} items meet Wikimedia upload criteria."
  end

  def wikimedia_uploads_tooltip
    "The number of files that have been uploaded into Wikimedia."
  end

  def wikimedia_files_used_tooltip
    "The number of your files that are currently in use on Wikimedia pages."
  end

  def wikimedia_pages_enhanced_tooltip
    "The number of Wikimedia pages that include at least one of your files."
  end

  def wikimedia_views_tooltip
    "The all-time total page views of Wikimedia pages featuring your uploaded files."
  end

  def contributor_count_tooltip
    "The total number of contributing institutions currently indexed in DPLA for this hub."
  end

  def website_views_total_tooltip
    "All-time total views of your items on the DPLA website (dp.la), including the " \
    "digital library catalog, exhibitions, and primary source sets."
  end

  def wikimedia_views_total_tooltip
    "All-time total page views of Wikimedia pages featuring files uploaded from your collection."
  end

  # Fuller copy for the table pages; the short forms above stay as tooltips.

  def view_exhibition_description
    "Views of your items on DPLA exhibition pages. Each row is one of your
    items; the count is how many times visitors viewed it in an exhibition. Comparable to \"pageview\" in
    Google Analytics."
  end

  def view_primary_source_set_description
    "Views of your items on DPLA primary source set pages. Each source in a
    set has its own page featuring one item; the count is how many times
    visitors viewed your item's page.
    Comparable to \"pageview\" in Google Analytics."
  end

  def find_event_page_description(key)
    case key
    when "view_exhibit"
      view_exhibition_description
    when "view_pss"
      view_primary_source_set_description
    else
      find_tooltip(key)
    end
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
    when "Upload count"
      wikimedia_uploads_tooltip
    when "Files Used"
      wikimedia_files_used_tooltip
    when "Pages Enhanced"
      wikimedia_pages_enhanced_tooltip
    when "Page views"
      wikimedia_views_tooltip
    end
  end
end
