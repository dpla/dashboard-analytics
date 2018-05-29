module DateSetter
  extend ActiveSupport::Concern

  def min_date
    Date.new(Settings.min_date.year, Settings.min_date.month)
  end

  def max_date
    Date.today
  end

  def default_start_date
      Date.today.beginning_of_month
  end

  def default_end_date
    Date.today
  end

  ##
  # This assigns values to @start_date and @end_date using params[:start_date]
  # and params[:end_date], both of which are expected to be in the format
  # "YYYY-MM"
  # The default start date is the beginning of the current month.
  # The default end date is today.
  # DateSetter has access to controller params and instance variables.
  #
  def assign_start_and_end_dates
    start_year = parse_year(params[:start_date])
    start_month = parse_month(params[:start_date])
    @start_date = start_of_month(start_year, start_month)
    @end_date = default_end_date

    if params[:end_date].present?
      end_year = parse_year(params[:end_date])
      end_month = parse_month(params[:end_date])
      @end_date = end_of_month(end_year, end_month)
    else
      @end_date = end_of_start_month(@start_date)
    end

    @end_date = default_end_date if @end_date < @start_date
  end

  ##
  # Parse year from date.
  # Date param expected to be in format "YYYY-MM" or "YYYY-Q#"
  # @return Int | nil
  #
  def parse_year(date)
    date.split("-").first.to_i rescue nil
  end

  ##
  # Parse month from date.
  # Date param expected to be in format "YYYY-MM" or "YYYY-Q#"
  # @return Int | nil
  #
  def parse_month(date)
    date.split("-").last.to_i rescue nil
  end

  ##
  # Get the first day of a given month and year.
  # If month and year are missing or invalid, return default start date
  #
  # @param year Int | nil
  # @param month Int | nil
  # @return Date
  #
  def start_of_month(year, month)
    begin
      # will raise exception if params are missing or invalid
      start_date = Date.new(year, month)
      raise ArgumentError if start_date < min_date
      raise ArgumentError if start_date > max_date
      start_date
    rescue
      default_start_date
    end
  end

  def end_of_month(year, month)
    begin
      # will raise exception if params are missing or invalid
      end_date = Date.new(year, month).end_of_month
      raise ArgumentError if end_date > max_date
      end_date
    rescue
      default_end_date
    end
  end

  ##
  # Given the first day of a month, get the last day of that same month.
  # If the end of the given month is after the current date,
  # return default end date.
  #
  # @param Date
  # @return Date
  def end_of_start_month(start_date)
    begin
      end_date = start_date.end_of_month
      raise ArgumentError if end_date > max_date
      end_date
    rescue
      default_end_date
    end
  end
end
