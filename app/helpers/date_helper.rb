module DateHelper

  ##
  # For use with the grouped_options_for_select helper.
  # @see https://apidock.com/rails/ActionView/Helpers/FormOptionsHelper/grouped_options_for_select
  # @return Hash
  def date_form_options
    available_months.map do |date|
      label = "#{Date::ABBR_MONTHNAMES[date.month]} #{date.year}"
      value = date.strftime("%Y-%m") # YYYY-MM
      [label, value]
    end
  end

  ##
  # @return [Array<Date>] the first day of every available month
  def available_months
    first_date = Date.new(Settings.min_date.year, Settings.min_date.month)
    last_date = Date.today.beginning_of_month
    dates = [first_date]

    loop do
      break if dates.last == last_date
      dates.push(dates.last.next_month.beginning_of_month)
    end

    dates
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
