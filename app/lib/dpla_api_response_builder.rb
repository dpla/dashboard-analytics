require 'httparty'

class DplaApiResponseBuilder
  include HTTParty
  base_uri Settings.dpla_api.base_uri

  ##
  # @return [Array<String>]
  #
  def hubs
    options = { query: { api_key: api_key,
                         facets: 'provider.name',
                         page_size: 0 } }

    begin
      json_response('/items', options)['facets']['provider.name']['terms']
        .map{ |f| f['term'] }
    rescue Exception => e
      Rails.logger.debug(e)
      Array.new
    end
  end

  ##
  # @param [String]
  # @return [Array<String>]
  #
  def contributors(hub)
    options = { query: { :api_key => api_key,
                         :facets => 'dataProvider',
                         :page_size => 0, 
                         :facet_size => 2000,
                         :'provider.name' => hub } }

    begin
      json_response('/items', options)['facets']['dataProvider']['terms']
        .map{ |f| f['term'] }
    rescue Exception => e
      Rails.logger.debug(e)
      Array.new
    end
  end

  ##
  # @param [String]
  # @return [Array<Hash>]
  #
  def contributors_item_count(hub)
    options = { query: { :api_key => api_key,
                         :facets => 'dataProvider',
                         :page_size => 0, 
                         :facet_size => 2000,
                         :'provider.name' => hub } }

    begin
      json_response('/items', options)['facets']['dataProvider']['terms']
    rescue Exception => e
      Rails.logger.debug(e)
      Array.new
    end
  end

  ##
  # @param hub [String]
  # @param contributor [String]
  # @return [Int|Nil]
  #
  def item_count(hub, contributor = nil)
    query = { :api_key => api_key,
              :page_size => 0, 
              :'provider.name' => hub }

    query[:dataProvider] = contributor if contributor.present?

    options = { query: query }

    begin
      count = json_response('/items', options)['count']
      if (count.is_a? Integer)
        count # ElasticSearch 6
      else
        count['value'] # ElasticSearch 7
      end
    rescue Exception => e
      Rails.logger.debug(e)
    end
  end

  ##
  # @param hub [String]
  # @param contributor [String]
  # @return [Int|Nil]
  #
  def bws_item_count(hub, contributor = nil)
    query = { :api_key => api_key,
              :page_size => 0, 
              :'provider.name' => hub,
              :filter => "tags:blackwomensuffrage" }

    query[:dataProvider] = contributor if contributor.present?

    options = { query: query }

    begin
      count = json_response('/items', options)['count']
      if (count.is_a? Integer)
        count # ElasticSearch 6
      else
        count['value'] # ElasticSearch 7
      end
    rescue Exception => e
      Rails.logger.debug(e)
    end
  end

  ##
  # @param [String]
  # @return [Array<Hash>]
  #
  def contributors_bws_item_count(hub)
    options = { query: { :api_key => api_key,
                         :facets => 'dataProvider',
                         :page_size => 0, 
                         :facet_size => 2000,
                         :'provider.name' => hub,
                         :filter => "tags:blackwomensuffrage" } }

    begin
      json_response('/items', options)['facets']['dataProvider']['terms']
        .map{ |t| [t["term"], t["count"]] }.to_h
    rescue Exception => e
      Rails.logger.debug(e)
      Array.new
    end
  end

  private

  def api_key
    Settings.dpla_api.key
  end

  def json_response(path, options)
    JSON.parse(response(path, options).to_json)
  end

  ##
  # Make HTTP request.
  # Retry in event of relevant server error.
  #
  # @return [HTTParty::Response] | nil
  #
  def response(path, options)
    tries ||= 0
    res = self.class.get(path, options)

    if res.code != 200
      Rails.logger.debug("A #{res.code} error occurred when attempting to call the DPLA API")
      raise HttpServerError if res.code.in? [500, 502, 503, 504]
    end

    res
  rescue HttpServerError
    # Use exponential backoff to delay next request attempt.
    sleep(2**tries + rand) and retry unless(tries += 1) == 3
  end
end

class HttpServerError < StandardError; end
