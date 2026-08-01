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
    month_start(Settings.min_date)
  end

  # First day of the earliest month with per-item event data. GA4 registered
  # the event_label dimension Jul 18, 2025; earlier months return no rows.
  def events_min_date
    month_start(Settings.events_min_date)
  end

  # Last day of the last completed month.
  def max_date
    Date.current.beginning_of_month - 1
  end

  # Settings floors are { month:, year: }.
  def month_start(setting)
    Date.new(setting.year.to_i, setting.month.to_i)
  end
end
