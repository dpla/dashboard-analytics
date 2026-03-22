require 'csv'

class ApiSearchTerms

  ##
  # @return [ApiSearchTerms]
  #
  # @example
  #   ApiSearchTerms.build do |builder|
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
    @start_date = nil
    @end_date = nil
  end

  def start_date=(start_date)
    @start_date = start_date
  end

  def end_date=(end_date)
    @end_date = end_date
  end

  # API search term data is not tracked in GA4 — no data available.
  def response
    nil
  end

  def multi_page_response
    []
  end

  def to_csv
    CSV.generate({ headers: true }) do |csv|
      csv << ["Search term", "Count"]
    end
  end

end
