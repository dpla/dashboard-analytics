class Hub

  ##
  # Get all the hub names from the DPLA API
  # @return [Array<String>]
  #
  def self.all
    dpla_api.hubs.sort
  end

  ##
  # Get all hubs with their DPLA item counts (single API call, already sorted)
  # @return [Array<Hash>] each hash has 'term' (hub name) and 'count' (item count)
  #
  def self.all_with_counts
    Rails.cache.fetch("hub:all_with_counts", expires_in: 1.hour) do
      result = dpla_api.hubs_with_counts
      result.presence
    end || []
  end

  ##
  # Initialize a single hub
  # 
  # @param name [String]
  # @param start_date [Date]
  # @param end_date [Date]
  #
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

  ##
  # Get names of all contributors that belonging to this hub
  # @return [Array<String>]
  def contributors
    @contributors ||= self.class.dpla_api.contributors(name).sort
  end

  protected

  def self.dpla_api
    @@dpla_api ||= DplaApiResponseBuilder.new()
  end
end
