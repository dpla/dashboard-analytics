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

  # "Showing X-Y of Z items." caption for a paginated table.
  def page_window(total, visible_count, unit)
    range = visible_count.zero? ? "0" :
      "#{number_with_delimiter(page_offset + 1)}-#{number_with_delimiter(page_offset + visible_count)}"
    "Showing #{range} of #{number_with_delimiter(total)} #{unit}."
  end
end
