module DateMenuHelper
  def date_form_options
    available_dates.map do |date|
      label = "#{Date::ABBR_MONTHNAMES[date.month]} #{date.year}"
      value = date.strftime("%Y-%m") # YYYY-MM
      [label, value]
    end
  end

  def available_dates
    first_date = Date.new(Settings.min_date.year, Settings.min_date.month)
    last_date = Date.today.beginning_of_month
    dates = [first_date]

    loop do
      dates.push(dates.last.next_month.beginning_of_month)
      break if dates.last == last_date 
    end

    dates
  end

  def selected_date
    return unless @start_date
    @start_date.strftime("%Y-%m") # YYYY-MM
  end

  def api_data_for_date_range?
    api_min_date = Date.new(Settings.api_min_date.year, 
                            Settings.api_min_date.month)

    if (@start_date && @start_date >= api_min_date)
      true
    else 
      false
    end
  end
end
