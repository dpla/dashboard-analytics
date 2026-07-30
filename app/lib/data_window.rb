##
# Months the dashboard displays: Settings.min_date through the last
# completed month. Current month excluded; it still changes. Completed
# months never change, so responses cache for good (GaPersistentCache).
#
# Single source of window bounds (DateSetter, DateHelper, warm job).
#
module DataWindow
  module_function

  # First day of the earliest month with data.
  def min_date
    Date.new(Settings.min_date.year.to_i, Settings.min_date.month.to_i)
  end

  # Last day of the last completed month.
  def max_date
    Date.current.beginning_of_month - 1
  end
end
