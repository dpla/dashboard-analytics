class WebsiteEvents
  include GaCacheable

  # Website event types shown as event sub-pages, keyed by URL slug.
  NAMES_BY_ID = {
    "view_item"     => "View Item",
    "view_exhibit"  => "View Exhibition Item",
    "view_pss"      => "View Primary Source",
    "click_through" => "Click Through",
  }.freeze

  # Columns WebsiteEventsPresenter reads: "id : title", contributor, count.
  COLUMNS = %w(ga:eventLabel ga:eventAction ga:totalEvents).freeze

  ##
  # @return [WebsiteEvents]
  #
  # @example
  #   WebsiteEvents.build do |builder|
  #     builder.hub = "California Digital Library"
  #     builder.contributor = "Agua Caliente Cultural Museum"
  #     builder.start_date = Date.yesterday
  #     builder.end_date = Date.today
  #     builder.event_name = "Click Through"
  #   end
  #
  def self.build
    builder = new
    yield(builder)
    builder
  end

  def initialize
    @hub = nil
    @contributor = nil
    @start_date = nil
    @end_date = nil
    @event_name = nil
    @page = nil
  end

  def hub=(hub)
    @hub = hub
  end

  def hub
    @hub
  end

  def contributor=(contributor)
    @contributor = contributor
  end

  def contributor
    @contributor
  end

  def start_date=(start_date)
    @start_date = start_date
  end

  def end_date=(end_date)
    @end_date = end_date
  end

  def event_name=(event_name)
    @event_name = event_name
  end

  def event_name
    @event_name
  end

  # 1-based page for #response. CSV exports ignore it.
  def page=(page)
    @page = page
  end

  # One page of rows, or nil on error. With one era GA4 does the paging.
  # With two, both exports are merged and paged here.
  def response
    @response ||= if eras.one?
      era = eras.first
      fetch_cached("page#{@page}") { canonical(era, builder_for(era, page: @page).response) }
    else
      page_of(merged)
    end
  rescue => e
    Rails.logger.error(e)
    nil
  end

  # Every row, in pages, for the CSV export. Empty array on error.
  def multi_page_response
    @multi_page_response ||= eras.one? ? era_pages(eras.first) : [merged]
  rescue => e
    Rails.logger.error(e)
    Array.new
  end

  private

  def builder_for(era, page: nil)
    GaResponseBuilder.build do |builder|
      builder.start_date = era.start_date.iso8601
      builder.end_date = era.end_date.iso8601
      builder.metrics = %w(ga:totalEvents)
      builder.dimensions = era.schema::ITEM_DIMENSIONS
      builder.filters = era.schema.event_filters(@event_name, @hub, @contributor)
      builder.sort = %w(-ga:totalEvents) # Descending
      builder.page = page
    end
  end

  # One GA4 page rewritten into COLUMNS, whatever shape the era sent.
  def canonical(era, page)
    build_response(COLUMNS, page.rows.to_a.map { |row| era.schema.item_row(row) },
                   totals: page.totals_for_all_results, total_results: page.total_results)
  end

  # One era's full export, cached on its own. The legacy era never
  # changes, so later ranges reuse it.
  def era_pages(era)
    fetch_cached("multi", memory: false, range: era) do
      builder_for(era).multi_page_response.map { |page| canonical(era, page) }
    end
  end

  # Both exports as one page, one row per item, most viewed first.
  # The label and contributor come from the later era.
  def merged
    @merged ||= begin
      counts = Hash.new(0)
      details = {}
      fetch_eras { |era| era_pages(era) }.flatten.each do |page|
        page.rows.to_a.each do |label, contributor, count|
          id = GaResponsePresenter.item_id(label).to_s
          counts[id] += count.to_i
          details[id] = [label, contributor]
        end
      end
      rows = counts.sort_by { |id, count| [-count, id] }
                   .map { |id, count| [*details[id], count.to_s] }
      build_response(COLUMNS, rows)
    end
  end

  def page_of(export)
    build_response(COLUMNS, PaginationHelper.page_slice(export.rows, @page),
                   total_results: export.total_results)
  end
end
