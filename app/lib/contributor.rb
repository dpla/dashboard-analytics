class Contributor

  ##
  # Initialize a single contributor
  # 
  # @param name [String]
  # @param hub_name [String]
  # @param start_date [Date]
  # @param end_date [Date]
  #
  def initialize(name, hub_name, start_date, end_date)
    @name = name
    @hub = Hub.new(hub_name, start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  def name
    @name
  end

  def hub
    @hub
  end

  def start_date
    @start_date.iso8601
  end

  def end_date
    @end_date.iso8601
  end

  def ga_token
    @frontend_ga.token
  end

  def overview
    Overview.new(self)
  end

  def metadata_completeness
    MetadataCompleteness.new(self)
  end

  def events(event_type)
    Events.new(self, event_type)
  end

  def frontend_ga
    @frontend_ga ||= FrontendAnalytics.new(start_date, end_date)
  end

  def api_ga
    @api_ga ||= ApiAnalytics.new(start_date, end_date)
  end
end
