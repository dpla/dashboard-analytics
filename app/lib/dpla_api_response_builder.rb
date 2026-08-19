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

  # Fields the DPLA index stamps onto items in curated content.
  CURATED_FIELDS = {
    exhibitions: 'exhibitions',
    primary_source_sets: 'primarySourceSets',
  }.freeze

  # Covers all 32 exhibitions and 142 source sets.
  CURATED_FACET_SIZE = 200

  # The API caps each parameter at 200 characters,
  # which fits five 32-character IDs.
  CURATED_ID_BATCH = 5

  # Runs during page render, so one short attempt and no retries.
  CURATED_TIMEOUT_SECONDS = 3

  ##
  # Which exhibitions or primary source sets hold an institution's items.
  #
  # @param kind [Symbol] :exhibitions or :primary_source_sets
  # @param hub [String] provider name
  # @param contributor [String, nil] dataProvider name
  # @return [Hash<String, Integer>, nil] { slug => item count }; {} when
  #   there are none, nil when the request failed so callers can fail open.
  #
  def curated_breakdown(kind, hub, contributor = nil)
    field = CURATED_FIELDS.fetch(kind)
    query = {
      'facets' => field,
      'facet_size' => CURATED_FACET_SIZE,
      'provider.name' => %("#{hub.delete('"')}"),
      'page_size' => 0,
      'api_key' => api_key,
    }
    query['dataProvider.name'] = %("#{contributor.delete('"')}") if contributor

    res = self.class.get('/items', query: query, timeout: CURATED_TIMEOUT_SECONDS)
    return nil unless res.code == 200

    terms = JSON.parse(res.body).dig('facets', field, 'terms') || []
    terms.to_h { |term| [term['term'], term['count'].to_i] }
  rescue StandardError => e
    Rails.logger.warn("DplaApiResponseBuilder#curated_breakdown: #{e.class}: #{e.message}")
    nil
  end

  ##
  # Which curated content holds each of the given items. Uses the search
  # endpoint rather than the multi-ID path endpoint, which errors on some
  # mixes of IDs no longer in the index.
  #
  # @param kind [Symbol] :exhibitions or :primary_source_sets
  # @param ids [Array<String>] DPLA item hex IDs
  # @return [Hash<String, Array<String>>] { item_id => [slug, ...] }; items
  #   with no membership are omitted, and {} on failure — the annotation is
  #   optional, so callers carry on without it.
  #
  def curated_memberships_for_items(kind, ids)
    result = {}
    field = CURATED_FIELDS.fetch(kind)

    ids.filter_map { |id| id&.strip.presence }.uniq.each_slice(CURATED_ID_BATCH) do |batch|
      query = {
        'id' => batch.join(' OR '),
        'fields' => "id,#{field}",
        'page_size' => batch.size,
        'api_key' => api_key,
      }
      res = self.class.get('/items', query: query, timeout: CURATED_TIMEOUT_SECONDS)
      next unless res.code == 200

      (JSON.parse(res.body)['docs'] || []).each do |doc|
        # `fields` returns a lone membership as a bare string, not an array.
        slugs = Array(doc[field]).map(&:to_s).reject(&:empty?)
        result[doc['id']] = slugs if doc['id'] && slugs.any?
      end
    end
    result
  rescue StandardError => e
    Rails.logger.warn("DplaApiResponseBuilder#curated_memberships_for_items: #{e.class}: #{e.message}")
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
