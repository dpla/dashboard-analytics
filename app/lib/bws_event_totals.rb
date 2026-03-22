class BwsEventTotals

  ##
  # @return [BwsEventTotals]
  #
  # @example
  #   BwsEventTotals.build do |builder|
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

  def view_events
    item_events + exhibit_events + pss_events
  end

  def item_events
    parse_response['View Item'].to_i rescue 0
  end

  def click_throughs
    parse_response['Click Through'] || 0
  end

  # BWS usage data is not tracked in GA4 — no data available.
  def response
    nil
  end

  private

  def parse_response
    Hash.new
  end
end
