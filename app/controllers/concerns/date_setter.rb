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
  # This assigns values to @start_date and @end_date using params[:date].
  # params[:date] is expected to be in format "YYYY-MM" or "YYYY-Q#"
  # The default start date is the beginning of the current month.
  # The default end date is today.
  # DateSetter has access to controller params and instance variables.
  #
  def assign_start_and_end_dates
    year = parse_year
    month = parse_month
    quarter = parse_quarter

    if quarter
      @start_date = start_of_quarter(year, quarter)
      @end_date = end_of_quarter(@start_date)
    else
      @start_date = start_of_month(year, month)
      @end_date = end_of_month(@start_date)
    end
  end

  ##
  # Parse year from date param.
  # Date param expected to be in format "YYYY-MM" or "YYYY-Q#"
  # @return Int | nil
  #
  def parse_year
    params[:date].split("-").first.to_i rescue nil
  end

  ##
  # Parse month from date param.
  # Date param expected to be in format "YYYY-MM" or "YYYY-Q#"
  # @return Int | nil
  #
  def parse_month
    params[:date].split("-").last.to_i rescue nil
  end

  ##
  # Parse quarter from date param.
  # Date param expected to be in format "YYYY-MM" or "YYYY-Q#"
  # @return Int | nil
  #
  def parse_quarter
    quarter = params[:date].split("-").last rescue ""
    return unless quarter.start_with?("Q")
    quarter.sub("Q", "").to_i rescue nil
  end

  ##
  # Given a quarter, return the first month of the quarter.
  # @param Int
  # @return Int
  #
  def quarter_start_month(q)
    (q*3)-2
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

  ##
  # Get the first day of a given quarter and year.
  # If quarter and day are missing or invalid, return default start date.
  #
  # @param year Int | nil
  # @param quarter Int | nil
  # @return Date
  #
  def start_of_quarter(year, quarter)
    begin
      # will raise exception if params are missing or invalid
      month = quarter_start_month(quarter)
      start_date = Date.new(year, month)
      raise ArgumentError if start_date < min_date
      raise ArgumentError if start_date > max_date
      start_date
    rescue
      default_start_date
    end
  end

  ##
  # Given the first day of a month, get the last day of that same month.
  # If the end of the given month is after the current date,
  # return default end date.
  #
  # @param Date
  # @return Date
  def end_of_month(start_date)
    begin
      end_date = start_date.end_of_month
      raise ArgumentError if end_date > max_date
      end_date
    rescue
      default_end_date
    end
  end

  ##
  # Given the first day of a quarter, get the last day of that same quarter.
  # If the end of the given quarter is after the current date,
  # return default end date.
  #
  # @param Date
  # @return Date
  #
  def end_of_quarter(start_date)
    begin
      end_date = start_date.end_of_quarter
      raise ArgumentError if end_date > max_date
      end_date
    rescue
      default_end_date
    end
  end
end
