class Hub
  def self.all
    all_with_counts.map { |h| h["term"] }
  end

  ##
  # @return [Array<Hash>] [{ "term" => hub_name, "count" => item_count }, ...] sorted by name
  #
  def self.all_with_counts
    HubStats.fetch["hubs"].map { |name, data|
      { "term" => name, "count" => data["item_count"] }
    }.sort_by { |h| h["term"] }
  rescue => e
    Rails.logger.warn("Hub.all_with_counts failed: #{e.class}: #{e.message}")
    []
  end

  ##
  # @param hub [String]
  # @param contributor [String, nil]
  # @return [Integer, nil]
  #
  def self.item_count(hub, contributor = nil)
    dig_count(HubStats.fetch, hub, contributor) || 0
  end

  ##
  # @param hub [String]
  # @param contributor [String, nil]
  # @return [Integer]
  #
  def self.bws_item_count(hub, contributor = nil)
    dig_count(HubStats.fetch_bws, hub, contributor) || 0
  end

  ##
  # @param hub [String]
  # @return [Array<String>] sorted contributor names
  #
  def self.contributors(hub)
    (HubStats.fetch.dig("hubs", hub, "contributors") || {}).keys.sort
  end

  ##
  # @param hub [String]
  # @return [Array<Hash>] [{ "term" => name, "count" => count }, ...] sorted by count desc
  #
  def self.contributors_item_count(hub)
    (HubStats.fetch.dig("hubs", hub, "contributors") || {})
      .map { |name, count| { "term" => name, "count" => count } }
      .sort_by { |c| -c["count"] }
  end

  ##
  # @param hub [String]
  # @return [Hash] { contributor_name => bws_item_count }
  #
  def self.contributors_bws_item_count(hub)
    HubStats.fetch_bws.dig("hubs", hub, "contributors") || {}
  end

  def initialize(name, start_date, end_date)
    @name = name
    @start_date = start_date
    @end_date = end_date
  end

  def name
    @name
  end

  def start_date
    @start_date.iso8601
  end

  def end_date
    @end_date.iso8601
  end

  def contributors
    self.class.contributors(@name)
  rescue => e
    Rails.logger.warn("Hub#contributors failed for #{@name} (#{e.class}): #{e.message}")
    []
  end

  private_class_method def self.dig_count(data, hub, contributor)
    if contributor.present?
      data.dig("hubs", hub, "contributors", contributor)
    else
      data.dig("hubs", hub, "item_count")
    end
  end
end
