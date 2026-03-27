##
# Provides participant lookup against the institutions_v2.json file used by
# the Wikimedia upload pipeline. Only hubs/institutions with upload: true are
# considered active pipeline participants.
#
# The JSON is fetched once and cached for 24 hours so individual page renders
# don't make outbound HTTP calls.
#
class WikimediaParticipants
  INSTITUTIONS_URL = WikimediaCacheBuilder::INSTITUTIONS_URL
  CACHE_KEY        = "wikimedia:institutions_v2"
  CACHE_TTL        = 24.hours

  ##
  # Returns true if the hub is an active Wikimedia upload participant.
  #
  # @param hub [String]
  # @return [Boolean]
  #
  def self.hub?(hub)
    data = fetch
    data.dig(hub, "upload") == true
  end

  ##
  # Returns true if the contributor (within a hub) is an active Wikimedia
  # upload participant.
  #
  # @param hub         [String]
  # @param contributor [String]
  # @return [Boolean]
  #
  def self.contributor?(hub, contributor)
    data = fetch
    data.dig(hub, "institutions", contributor, "upload") == true
  end

  private

  def self.fetch
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      uri      = URI(INSTITUTIONS_URL)
      response = Net::HTTP.get_response(uri)
      JSON.parse(response.body)
    end
  rescue StandardError => e
    Rails.logger.error("[WikimediaParticipants] Failed to fetch institutions JSON: #{e.message}")
    {}
  end
end
