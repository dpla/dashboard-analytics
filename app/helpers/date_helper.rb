module DateHelper

  ##
  # For use with the grouped_options_for_select helper.
  # @see https://apidock.com/rails/ActionView/Helpers/FormOptionsHelper/grouped_options_for_select
  # @return Hash
  def start_date_form_options
    available_months.map do |date|
      label = "#{Date::ABBR_MONTHNAMES[date.month]} #{date.beginning_of_month.day}, #{date.year}"
      value = date.strftime("%Y-%m") # YYYY-MM
      [label, value]
    end
  end

  ##
  # For use with the grouped_options_for_select helper.
  # @see https://apidock.com/rails/ActionView/Helpers/FormOptionsHelper/grouped_options_for_select
  # @return Hash
  def end_date_form_options
    available_months.map do |date|
      label = "#{Date::ABBR_MONTHNAMES[date.month]} #{date.end_of_month.day}, #{date.year}"
      value = date.strftime("%Y-%m") # YYYY-MM
      [label, value]
    end
  end

  ##
  # @return [Array<Date>] first day of every month from picker_min_date
  #   to max_date (narrowed by EventsController#min_date, GaDataFloor)
  def available_months
    @available_months ||= begin
      last_date = max_date.beginning_of_month
      dates = [picker_min_date]
      dates.push(dates.last.next_month) while dates.last < last_date
      dates
    end
  end

  # Date-menu bounds, e.g. "Jun 2026".
  def data_available_from
    picker_min_date.strftime("%b %Y")
  end

  def data_available_through
    DataWindow.max_date.strftime("%b %Y")
  end

  def api_data_for_date_range?
    api_min_date = Date.new(Settings.api_min_date.year.to_i, 
                            Settings.api_min_date.month.to_i)

    if (@start_date && @start_date >= api_min_date)
      true
    else
      false
    end
  end

  def bws_data_for_date_range?
    bws_min_date = Date.new(Settings.bws_min_date.year.to_i,
                            Settings.bws_min_date.month.to_i)

    if (@start_date && @start_date >= bws_min_date)
      true
    else
      false
    end
  end

end
