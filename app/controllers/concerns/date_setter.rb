module DateSetter
  extend ActiveSupport::Concern

  def min_date
    Date.new(2018, 01)
  end

  def max_date
    # For last month: Date.today.last_month.end_of_month
    Date.today
  end

  ##
  # Get the first day of a given month and year.
  # If month and day are missing or invalid, return first day of current month.
  #
  # @param Hash
  # @return Date
  def get_start_date(params)
    begin
      # will raise exception if params are missing or invalid
      start_date = Date.new(params[:year].to_i, params[:month].to_i)
      raise ArgumentError if start_date < min_date
      raise ArgumentError if start_date > max_date
      start_date
    rescue
      # For last month: Date.today.last_month.beginning_of_month
      Date.today.beginning_of_month
    end
  end

  ##
  # Given the first day of a month, get the last day of that same month.
  # If the end of the given month is after the current date, return the current
  # date.
  #
  # @param Date
  # @return Date
  def get_end_date(start_date)
    begin
      end_date = start_date.end_of_month
      raise ArgumentError if end_date > max_date
      end_date
    rescue
      # For last month: Date.today.last_month.end_of_month
      Date.today
    end
  end
end
