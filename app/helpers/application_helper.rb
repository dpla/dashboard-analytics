module ApplicationHelper

  def current_start_date
    @start_date.strftime("%Y-%m") rescue nil
  end

  def current_end_date
    @end_date.strftime("%Y-%m") rescue nil
  end

  def date_opts
    # The default view (no params) always shows the current month. Omit params
    # from links when the selected range matches the default so URLs stay clean.
    current_month = Date.current.strftime("%Y-%m")
    return {} if current_start_date == current_month && current_end_date == current_month

    { start_date: current_start_date, end_date: current_end_date }
  end
end
