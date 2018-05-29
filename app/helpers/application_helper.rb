module ApplicationHelper

  def current_start_date
    @start_date.strftime("%Y-%m") rescue nil
  end

  def current_end_date
    @end_date.strftime("%Y-%m") rescue nil
  end

  def date_opts
    { start_date: current_start_date, end_date: current_end_date }
  end
end
