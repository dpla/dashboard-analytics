module DateMenuHelper
  def date_form_options
    available_dates.map do |date|
      label = "#{Date::ABBR_MONTHNAMES[date.month]} #{date.year}"
      value = date.month
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
    @start_date.month
  end
end
