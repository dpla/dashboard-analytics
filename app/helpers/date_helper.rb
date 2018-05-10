module DateHelper

  ##
  # For use with the grouped_options_for_select helper.
  # @see https://apidock.com/rails/ActionView/Helpers/FormOptionsHelper/grouped_options_for_select
  # @return Hash
  def date_form_options
    months = available_months.map do |date|
      label = "#{Date::ABBR_MONTHNAMES[date.month]} #{date.year}"
      value = date.strftime("%Y-%m") # YYYY-MM
      [label, value]
    end

    quarters = available_quarters.map do |date|
      q_name = quarter_from_month(date.month)
      label = "#{q_name} #{date.year}"
      value = "#{date.year.to_s}-#{q_name}" # YYYY-Q#
      [label, value]
    end

    { 'Month' => months, 'Quarter' => quarters }
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

  ##
  # @return [Array<Date>] the first day of every available quarter
  def available_quarters
    first_date = Date.new(Settings.min_date.year, Settings.min_date.month)
    last_date = Date.today

    # Get the first full quarter in the available date range
    first_quarter = first_date.beginning_of_quarter.month == first_date.month ?
      first_date.beginning_of_quarter :
      first_date.next_quarter.beginning_of_quarter

    # Get the quarter that includes the current date
    last_quarter = last_date.beginning_of_quarter

    dates = [first_quarter]

    loop do
      break if dates.last == last_quarter
      dates.push(dates.last.next_quarter.beginning_of_quarter)
    end

    dates
  end

  ##
  # Get the quarter for a given month.
  # @return String
  # E.g. quarter_from_month(4) => "Q2"
  def quarter_from_month(m)
    "Q" + ((m+2)/3).to_s
  end

  def selected_date
    params[:date] ? params[:date] : @start_date.strftime("%Y-%m")
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
