class Hub

  ##
  # Get all the hub names from the DPLA API
  # @return [Array<String>]
  #
  def self.all
    dpla_api.hubs.sort
  end

  ##
  # Initialize a single hub
  # 
  # @param name [String]
  # @param start_date [String]
  # @param end_date [String]
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

  def ga_token
    frontend_ga.token
  end

  ##
  # Get names of all contributors that belonging to this hub
  # @return [Array<String>]
  def contributors
    @contributors ||= self.class.dpla_api.contributors(name).sort
  end

  def overview
    Overview.new(self)
  end

  def metadata_completeness
    MetadataCompleteness.new(self)
  end

  def events(event_id)
    Events.new(self, event_id)
  end

  def contributor_comparison
    ContributorComparison.new(self)
  end

  protected

  def self.dpla_api
    @@dpla_api ||= DplaApiResponseBuilder.new()
  end

  private

  def frontend_ga
    @frontend_ga ||= FrontendAnalytics.new(start_date, end_date)
  end
end
