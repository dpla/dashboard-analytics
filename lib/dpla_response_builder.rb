require 'httparty'

class DplaResponseBuilder
  include HTTParty
  base_uri Settings.dpla_api.base_uri

  def initialize
    @api_key = Settings.dpla_api.key
  end

  ##
  # @return [Array<String>]
  def hubs
    path = '/items'

    options = { query: {
        api_key: @api_key,
        facets: 'provider.name',
        page_size: 0
    } }
    
    r = response('/items', options)
    terms = []

    if r.ok?
      terms = JSON.parse(r.to_json)['facets']['provider.name']['terms']
        .map{ |f| f['term'] }
    else
      # TODO: log error message
    end

    return terms
  end

  ##
  # @return [HTTParty::Response] | nil
  def response(path, options)
    response = nil

    begin
      response = self.class.get(path, options)
    rescue Exception => msg
      # TODO: log msg
      # TODO: retry request if appropriate
    end

    return response
  end
end
