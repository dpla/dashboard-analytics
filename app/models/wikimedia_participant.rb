##
# Records whether a hub contributor is a Wikimedia pipeline participant,
# as determined by the upload flag in institutions_v2.json at cache build time.
# Hub-level upload: true cascades to all contributors in that hub.
#
# Populated by WikimediaCacheBuilder#sync_participant_flags during every rebuild.
# Queried at page load to choose the correct "no data" message without making
# any external API calls.
#
class WikimediaParticipant < ApplicationRecord
  self.table_name = "wikimedia_participants"

  def self.participant?(hub, contributor)
    where(hub: hub, contributor: contributor).pick(:participant) || false
  end

  def self.hub_participant?(hub)
    where(hub: hub, participant: true).exists?
  end
end
