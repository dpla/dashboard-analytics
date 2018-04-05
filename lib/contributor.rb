class Contributor

  @@dpla_api = DplaApiResponseBuilder.new()

  ##
  # Initialize a single hub
  # 
  # @param name [String]
  # @param start_date [String]
  # @param end_date [String]
  #
  def initialize(name, hub, start_date, end_date)
    @name = name
    @hub = hub
    @start_date = start_date
    @end_date = end_date
    @ga = GaResponseBuilder.new(start_date, end_date)
  end

  def name
    @name
  end

  def hub
    @hub
  end

end
