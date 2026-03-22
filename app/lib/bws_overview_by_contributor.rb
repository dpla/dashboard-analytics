class BwsOverviewByContributor

  ##
  # @return [BwsOverviewByContributor]
  #
  # @example
  #   BwsOverviewByContributor.build do |builder|
  #     builder.hub = "California Digital Library"
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
    @start_date = nil
    @end_date = nil
  end

  def hub=(hub)
    @hub = hub
  end

  def start_date=(start_date)
    @start_date = start_date
  end

  def end_date=(end_date)
    @end_date = end_date
  end

  # BWS usage data is not tracked in GA4 — no data available.
  def parse_data
    Hash.new
  end

  def response
    nil
  end
end
