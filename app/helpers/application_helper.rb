module ApplicationHelper

  def current_start_date
    @start_date.strftime("%Y-%m") rescue nil
  end

  def current_end_date
    @end_date.strftime("%Y-%m") rescue nil
  end
end
