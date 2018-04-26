module DateMenuHelper
  def dates
    first_date = Date.new(Settings.min_date.month, Settings.min_date.year)
    last_date = Date.today.beginning_of_month

    dates = [first_date]

    loop do
      dates.push(dates.last.next_month.beginning_of_month)
      break if dates.last == last_date 
    end
  end
end
