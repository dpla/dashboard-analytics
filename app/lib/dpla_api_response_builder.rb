require 'httparty'

class DplaApiResponseBuilder
  include HTTParty
  base_uri Settings.dpla_api.base_uri

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
    ids.filter_map { |id| id&.strip.presence }.uniq.each_slice(50) do |batch|
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
