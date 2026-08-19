# Shared pagination for data tables
# Fixed page size, driven by the :page query param.
module PaginationHelper
  PAGE_SIZE = 50

  def current_page
    [params[:page].to_i, 1].max
  end

  # Link params that carry the current page;
  # Empty on page 1 so URLs stay clean.
  def page_opts
    current_page > 1 ? { page: current_page } : {}
  end

  # The current page's slice of array
  def paginate(array)
    array.slice(page_offset, PAGE_SIZE) || []
  end

  # 0-based index of the first row on the current page.
  def page_offset
    (current_page - 1) * PAGE_SIZE
  end

  def total_pages(total)
    (total.to_i / PAGE_SIZE.to_f).ceil
  end

  ##
  # Page numbers to link: first, last, and a few either side of current.
  # nil marks a gap, shown as an ellipsis.
  #
  # @example [1, nil, 5, 6, 7, 8, 9, nil, 40]
  #
  def page_links(total_pages, current = current_page, around: 2)
    current = current.clamp(1, total_pages)
    shown = [1, total_pages, *(current - around)..(current + around)]
    shown = shown.select { |page| page.between?(1, total_pages) }.uniq.sort

    shown.each_with_object([]) do |page, list|
      gap = list.last ? page - list.last : 1
      # One page skipped: show it.
      # An ellipsis would take the same room.
      list << (gap == 2 ? page - 1 : nil) if gap > 1
      list << page
    end
  end

  ##
  # Where a "jump to page" form submits.
  # Taken from page_url, not the request:
  # tables render async, so the browser URL is not the one to post back to.
  #
  # @return [Array(String, Hash)] path, and query params to carry along
  #
  def pagination_form_target(page_url)
    uri = URI.parse(page_url.call(1))
    carried = Rack::Utils.parse_nested_query(uri.query.to_s)
      .except("page")
      .select { |_, value| value.is_a?(String) }
    [uri.path, carried]
  end

  # "Showing X-Y of Z items." caption for a paginated table.
  def page_window(total, visible_count, unit)
    range = visible_count.zero? ? "0" :
      "#{number_with_delimiter(page_offset + 1)}-#{number_with_delimiter(page_offset + visible_count)}"
    "Showing #{range} of #{number_with_delimiter(total)} #{unit}."
  end
end
