require 'httparty'

class DplaApiResponseBuilder
  include HTTParty
  base_uri Settings.dpla_api.base_uri

  API_KEY = Settings.dpla_api.key

  ##
  # @return [Array<String>]
  #
  def hubs
    options = { query: { api_key: API_KEY,
                         facets: 'provider.name',
                         page_size: 0 } }

    begin
      json_response('/items', options)['facets']['provider.name']['terms']
        .map{ |f| f['term'] }
    rescue Exception => e
      # TODO: Log error message
      Array.new
    end
  end

  ##
  # @param [String]
  # @return [Array<String>]
  #
  def contributors(hub)
    options = { query: { :api_key => API_KEY,
                         :facets => 'dataProvider',
                         :page_size => 0, 
                         :facet_size => 2000,
                         :'provider.name' => hub } }

    begin
      json_response('/items', options)['facets']['dataProvider']['terms']
        .map{ |f| f['term'] }
    rescue Exception => e
      # TODO: Log error message
      Array.new
    end
  end

  def json_response(path, options)
    JSON.parse(response(path, options).to_json)
  end

  ##
  # Make HTTP request
  #
  # @return [HTTParty::Response] | nil
  #
  # TODO: Improve exceptions based on response code
  # TODO: Retry request if appropriate
  #
  def response(path, options)
    res = self.class.get(path, options)
    
    if res.code != 200
      raise "A #{res.code} error occurred when attempting to call the DPLA API" 
    end

    res
  end
end
