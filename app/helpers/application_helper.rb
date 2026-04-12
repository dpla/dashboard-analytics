module ApplicationHelper

  # Returns a formatted number or an em dash when value is nil (still loading).
  def dash_or(value, delimiter: ',')
    value.nil? ? "—" : number_with_delimiter(value, delimiter: delimiter)
  end

  ##
  # Wrapper around render_async that adds a default error message shown when
  # the async request fails instead of silently replacing the container with
  # an empty string.
  #
  def render_async_section(path, options = {}, &block)
    default_error = '<div class="error-message">Data unavailable. Please try refreshing.</div>'
    render_async(path, { error_message: default_error }.merge(options), &block)
  end

  def current_start_date
    @start_date.strftime("%Y-%m") rescue nil
  end

  def current_end_date
    @end_date.strftime("%Y-%m") rescue nil
  end

  ##
  # Returns true when the user has explicitly chosen a date range via URL params.
  # Partials use this to show "not time-bound" notes in date-invariant sections.
  #
  def date_range_active?
    params[:start_date].present? || params[:end_date].present?
  end

  def date_opts
    # The default view (no params) always shows the current month. Omit params
    # from links when the selected range matches the default so URLs stay clean.
    current_month = Date.current.strftime("%Y-%m")
    return {} if current_start_date == current_month && current_end_date == current_month

    { start_date: current_start_date, end_date: current_end_date }
  end
end
