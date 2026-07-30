module DateSetter
  extend ActiveSupport::Concern

  def min_date
    DataWindow.min_date
  end

  # Last day of the last completed month (see DataWindow).
  def max_date
    DataWindow.max_date
  end

  # Also the fallback for out-of-range params: a current-month date clamps
  # to the last completed month.
  def default_start_date
    max_date.beginning_of_month
  end

  def default_end_date
    max_date
  end

  ##
  # Set @start_date/@end_date to all available history (min_date through
  # the last completed month). For sections that always show all-time totals.
  #
  def assign_all_time_dates
    @start_date = min_date
    @end_date   = max_date
  end

  ##
  # Returns the effective [start, end] date range for a page section.
  # When date params are present use the requested range; otherwise fall back to all-time.
  # Requires assign_start_and_end_dates to have already been called.
  #
  # @return [Array<Date>] [sec_start, sec_end]
  #
  def section_date_range
    if params[:start_date].present?
      [@start_date, @end_date]
    else
      [min_date, max_date]
    end
  end

  ##
  # This assigns values to @start_date and @end_date using params[:start_date]
  # and params[:end_date], both of which are expected to be in the format
  # "YYYY-MM"
  # With a start date but no end date, @end_date is the end of the start month.
  # With neither, both dates fall back to the last completed month.
  # DateSetter has access to controller params and instance variables.
  #
  def assign_start_and_end_dates
    start_year = parse_year(params[:start_date])
    start_month = parse_month(params[:start_date])
    @start_date = start_of_month(start_year, start_month)

    if params[:end_date].present?
      end_year = parse_year(params[:end_date])
      end_month = parse_month(params[:end_date])
      @end_date = end_of_month(end_year, end_month)
    else
      @end_date = end_of_month(@start_date.year, @start_date.month)
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
end
