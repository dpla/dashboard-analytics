require 'httparty'

class DplaApiResponseBuilder
  include HTTParty
  base_uri Settings.dpla_api.base_uri

  ##
  # @return [Array<String>]
  #
  def hubs
    hubs_with_counts.map { |h| h['term'] }
  end

  ##
  # @return [Array<Hash>] each hash has 'term' (hub name) and 'count' (item count)
  #
  def hubs_with_counts
    options = { query: { api_key: api_key,
                         facets: 'provider.name',
                         page_size: 0 } }

    begin
      (json_response('/items', options).dig('facets', 'provider.name', 'terms') || [])
        .sort_by { |f| f['term'] }
    rescue StandardError => e
      Sentry.capture_exception(e)
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
      (json_response('/items', options).dig('facets', 'dataProvider', 'terms') || [])
        .map{ |f| f['term'] }
    rescue StandardError => e
      Sentry.capture_exception(e)
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
      json_response('/items', options).dig('facets', 'dataProvider', 'terms') || []
    rescue StandardError => e
      Sentry.capture_exception(e)
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
      return nil if count.nil?
      count.is_a?(Integer) ? count : count['value'] # Integer: ES6, Hash: ES7
    rescue StandardError => e
      Sentry.capture_exception(e)
      Rails.logger.debug(e)
      nil
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
              :tags => "blackwomensuffrage" }

    query[:dataProvider] = contributor if contributor.present?

    options = { query: query }

    begin
      count = json_response('/items', options)['count']
      return nil if count.nil?
      count.is_a?(Integer) ? count : count['value'] # Integer: ES6, Hash: ES7
    rescue StandardError => e
      Sentry.capture_exception(e)
      Rails.logger.debug(e)
      nil
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
                         :tags => "blackwomensuffrage" } }

    begin
      (json_response('/items', options).dig('facets', 'dataProvider', 'terms') || [])
        .map{ |t| [t["term"], t["count"]] }.to_h
    rescue StandardError => e
      Sentry.capture_exception(e)
      Rails.logger.debug(e)
      {}
    end
  end

  ##
  # Fetch dataProvider (contributing institution) names for a list of DPLA
  # item IDs. Returns a hash of { item_id => data_provider_name }.
  # IDs not found or missing dataProvider are omitted.
  #
  # @param ids [Array<String>] DPLA item hex IDs
  # @return [Hash<String, String>]
  #
  def data_providers_for_items(ids)
    return {} if ids.empty?

    result = {}
    ids.uniq.compact.each_slice(50) do |batch|
      begin
        docs = json_response("/items/#{batch.join(',')}", query: { api_key: api_key })['docs'] || []
        docs.each do |doc|
          item_hash = doc['id']&.split('/')&.last
          name = doc.dig('dataProvider', 'name')
          result[item_hash] = name if item_hash && name
        end
      rescue StandardError => e
        Sentry.capture_exception(e)
        Rails.logger.debug(e)
      end
    end
    result
  end

  private

  def api_key
    Settings.dpla_api.key
  end

  def json_response(path, options)
    res = response(path, options)
    return {} if res.nil?
    JSON.parse(res.to_json)
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
      raise HttpRateLimitError if res.code == 429
      raise HttpServerError if res.code.in? [500, 502, 503, 504]
    end

    res
  rescue HttpRateLimitError, HttpServerError => e
    if (tries += 1) < 3
      sleep(2**tries + rand)
      retry
    else
      Sentry.capture_exception(e)
      Rails.logger.warn("DPLA API request failed after #{tries} attempts: #{e.class}")
      nil
    end
  end
end

class HttpServerError < StandardError; end
class HttpRateLimitError < StandardError; end
