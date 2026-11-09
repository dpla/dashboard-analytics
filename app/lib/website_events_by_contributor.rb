class WebsiteEventsByContributor
  include GaCacheable

  ##
  # @return [WebsiteEventsByContributor]
  #
  # @example
  #   WebsiteEventsByContributor.build do |builder|
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

  def parse_data
    return Hash.new unless response.present? && response.rows.present?
    # Create Hash of data
    # e.g. "The Library" => { "Click Throughs" => 2, "Total Views" => 5 }
    data = {}

    response.rows.each do |r|
      event = r[0]
      contributor = r[1]
      count = r[2]&.to_i || 0

      data[contributor] ||= { "Views" => 0, "Click Throughs" => 0 }
      data[contributor]["Click Throughs"] += count if event == "Click Through"
      data[contributor]["Views"] += count if event.start_with?("View")
    end

    data
  end

  # Cached rows of [event name, contributor, count], summed across
  # eras. nil on error.
  def response
    @response ||= merge(era_responses)
  rescue => e
    Rails.logger.error(e)
    nil
  end

  private

  def builder_for(era)
    GaResponseBuilder.build do |builder|
      builder.start_date = era.start_date.iso8601
      builder.end_date = era.end_date.iso8601
      builder.metrics = %w(ga:totalEvents)
      builder.dimensions = [era.schema::EVENT_DIMENSION, era.schema::CONTRIBUTOR_DIMENSION]
      builder.filters = era.schema.hub_filters(@hub)
    end
  end

  def merge(responses)
    counts = Hash.new(0)
    eras.zip(responses) do |era, response|
      response.rows.to_a.each do |value, contributor, count|
        name = era.schema.event_name(value)
        next unless name

        counts[[name, GaEventSchema.contributor_key(contributor)]] += count.to_i
      end
    end
    build_response(%w(ga:eventCategory ga:eventAction ga:totalEvents),
                   counts.map { |(name, contributor), count| [name, contributor, count.to_s] })
  end
end
