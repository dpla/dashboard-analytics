class ApiEvents

  ##
  # @return [ApiEvents]
  #
  # @example
  #   ApiEvents.build do |builder|
  #     builder.hub = "California Digital Library"
  #     builder.contributor = "Agua Caliente Cultural Museum"
  #     builder.start_date = Date.yesterday
  #     builder.end_date = Date.today
  #   end
  #
  def self.build
    builder = new
    yield(builder)
    builder
  end

  def initialize
    @hub = nil
    @contributor = nil
    @start_date = nil
    @end_date = nil
    @event_name = "View API Item"
  end

  def hub=(hub)
    @hub = hub
  end

  def contributor=(contributor)
    @contributor = contributor
  end

  def start_date=(start_date)
    @start_date = start_date
  end

  def end_date=(end_date)
    @end_date = end_date
  end

  def event_name
    @event_name
  end

  # API usage data is not tracked in GA4 — no data available.
  def response
    nil
  end

  def multi_page_response
    []
  end
end
