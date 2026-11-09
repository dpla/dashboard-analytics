##
# Primary source set item views, counted from page views. The PSS API
# gives dpla-frontend no provider or item id for most sources, so the
# events carry no hub, item or contributor. PssSources maps a source
# page path back to all three.
#
class PssEvents
  include GaCacheable

  EVENT_ID   = "view_pss".freeze
  EVENT_NAME = WebsiteEvents::NAMES_BY_ID.fetch(EVENT_ID)

  # Source pages only. Set and index pages are not source views.
  PATH_BODY    = "/primary-source-sets/([^/]+)/sources/([0-9]+)/?".freeze
  PATH         = /\A#{PATH_BODY}\z/
  # GA4 filters use RE2 syntax, where the anchors are ^ and $.
  PATH_PATTERN = "^#{PATH_BODY}$".freeze

  ##
  # @return [PssEvents]
  #
  # @example
  #   PssEvents.build do |builder|
  #     builder.hub = "HathiTrust"
  #     builder.contributor = "University of Michigan"
  #     builder.start_date = Date.new(2023, 4, 1)
  #     builder.end_date = Date.new(2026, 8, 31)
  #   end
  #
  def self.build
    builder = new
    yield(builder)
    builder
  end

  attr_accessor :hub, :contributor, :end_date
  attr_reader :start_date
  # 1-based page for #response. CSV exports ignore it.
  attr_writer :page

  # No page views before pss_min_date. Clamping to it keeps every caller
  # on the one cached report.
  def start_date=(date)
    @start_date = [date, DataWindow.pss_min_date].max
  end

  def event_name
    EVENT_NAME
  end

  # One page of rows, or nil on error.
  def response
    @response ||= page_response(PaginationHelper.page_slice(rows, @page))
  rescue => e
    Rails.logger.error(e)
    nil
  end

  # Every row, for the CSV export. Empty array on error.
  def multi_page_response
    @multi_page_response ||= [page_response(rows)]
  rescue => e
    Rails.logger.error(e)
    Array.new
  end

  # Returns 0 on error.
  def total_views
    @total_views ||= attributed.sum { |_entry, count, _slug| count }
  rescue => e
    Rails.logger.error(e)
    0
  end

  # Set slugs by item id, from the same rows the table counts.
  def memberships
    @memberships ||= begin
      sets = Hash.new { |hash, item| hash[item] = [] }
      attributed.each { |entry, _count, slug| sets[entry["item"]] |= [slug] }
      sets
    end
  end

  private

  # The report is site-wide, so one cached response serves every hub.
  def cache_key_parts
    []
  end

  # This hub's rows as [label, contributor, views], most viewed first.
  # One item can be several sources, so their views add up.
  def rows
    @rows ||= begin
      views = Hash.new(0)
      details = {}
      attributed.each do |entry, count, _slug|
        item = entry["item"]
        views[item] += count
        details[item] ||= entry
      end

      views.sort_by { |item, count| [-count, item] }.map do |item, count|
        entry = details[item]
        ["#{item} : #{entry["title"]}", entry["contributor"].to_s, count.to_s]
      end
    end
  end

  # Page views this hub holds, as [source entry, views, set slug].
  # An item that has left the index has no hub, so it drops out.
  def attributed
    @attributed ||= begin
      sources = PssSources.sources
      site_rows.filter_map do |path, count|
        match = PATH.match(path)
        entry = match && sources["#{match[1]}/#{match[2]}"]
        next unless entry && PssSources.held_by?(entry, @hub, @contributor)

        [entry, count.to_i, match[1]]
      end
    end
  end

  # Site-wide source page views as [path, count]. None before the floor.
  def site_rows
    return [] if @end_date < @start_date

    @site_rows ||= fetch_cached { page_views_builder.multi_page_response }
      .flat_map { |page| page.rows.to_a }
  end

  def page_views_builder
    GaResponseBuilder.build do |builder|
      builder.start_date = @start_date.iso8601
      builder.end_date = @end_date.iso8601
      builder.metrics = %w(screenPageViews)
      builder.dimensions = %w(pagePath)
      builder.filters = ["pagePath=~#{PATH_PATTERN}"]
    end
  end

  def page_response(page_rows)
    build_response(WebsiteEvents::COLUMNS, page_rows, total_results: rows.size)
  end
end
