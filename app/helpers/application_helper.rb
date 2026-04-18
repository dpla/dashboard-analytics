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

  # Returns nil when no start_date param is present so the date dropdown
  # shows the first available option (earliest month) rather than the current month.
  def current_start_date
    params[:start_date].present? ? (@start_date.strftime("%Y-%m") rescue nil) : nil
  end

  def current_end_date
    return nil unless @end_date.respond_to?(:strftime)
    @end_date.strftime("%Y-%m")
  end

  ##
  # Returns true when the user has explicitly chosen a date range via URL params.
  # Partials use this to show "not time-bound" notes in date-invariant sections.
  #
  def date_range_active?
    params[:start_date].present? || params[:end_date].present?
  end

  def date_opts
    # Pass through whatever params are in the current request so date range
    # selections (including the current month) are preserved across navigation.
    # Return {} when no params are set so all-time links stay clean.
    return {} unless date_range_active?

    opts = {}
    opts[:start_date] = current_start_date if params[:start_date].present?
    opts[:end_date]   = current_end_date   if params[:end_date].present?
    opts
  end
end
