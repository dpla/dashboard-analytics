##
# dataProvider names by DPLA item ID, from the S3 file
# generate_hub_stats.py writes monthly.
#
class ItemDataProviders
  extend SThreeJsonMap

  KEY = "hub-stats/item_data_providers.json"

  s3_json_map KEY, "items"

  # { item_id => data_provider_name }
  def self.items
    entries
  end
end
