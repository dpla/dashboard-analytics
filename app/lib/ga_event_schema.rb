##
# The two shapes dp.la item events take in GA4, and which days use which.
# Legacy: event name = contributor, event_category = "View Item : {hub}",
# event_label = "{id} : {title}". Current: fixed event names plus
# partner, contributor, dpla_id and item_title params.
# Settings.new_dimensions_date splits them, because GA4 reports a custom
# dimension only from the day it was registered.
#
module GaEventSchema
  # Legacy event_category prefix => current event name.
  # browse_item is left out. The dashboard never counted browsing.
  EVENT_NAMES = {
    "View Item"            => "item_view",
    "View Exhibition Item" => "exhibition_item_view",
    "View Primary Source"  => "primary_source_view",
    "Click Through"        => "click_through",
  }.freeze

  # GA4 drops parameter values longer than this. The frontend clips to it.
  PARAM_VALUE_MAX = 100

  Era = Struct.new(:schema, :start_date, :end_date)

  # The eras a range spans, oldest first. Two if it crosses the switch date.
  def self.eras(start_date, end_date)
    switch = DataWindow.new_dimensions_date
    return [Era.new(Legacy, start_date, end_date)] if end_date < switch
    return [Era.new(Current, start_date, end_date)] if start_date >= switch

    [Era.new(Legacy, start_date, switch - 1), Era.new(Current, switch, end_date)]
  end

  # The first 40 chars, all the legacy shape kept. Both shapes key on it,
  # and ContributorComparison looks rows up by it.
  def self.contributor_key(name)
    name.to_s[0, GaResponseBuilder::GA4_EVENT_NAME_MAX_LENGTH]
  end

  # Filter strings use GaResponseBuilder's filter format.
  module Legacy
    EVENT_DIMENSION       = "ga:eventCategory".freeze
    CONTRIBUTOR_DIMENSION = "ga:eventAction".freeze
    ITEM_DIMENSIONS       = %w(ga:eventLabel ga:eventAction).freeze

    def self.hub_filters(hub, contributor = nil)
      with_contributor(%W(ga:eventCategory=@#{hub} ga:eventCategory!@Browse), contributor)
    end

    def self.event_filters(event_name, hub, contributor = nil)
      with_contributor(["ga:eventCategory==#{event_name} : #{hub}"], contributor)
    end

    # "View Item : Some Hub" => "View Item"
    def self.event_name(value)
      value.to_s.split(" : ").first
    end

    # Legacy rows are already [label, contributor, count].
    def self.item_row(row)
      row
    end

    def self.with_contributor(filters, contributor)
      filters << "ga:eventAction==#{GaEventSchema.contributor_key(contributor)}" if contributor
      filters
    end
    private_class_method :with_contributor
  end

  module Current
    EVENT_DIMENSION       = "eventName".freeze
    CONTRIBUTOR_DIMENSION = "customEvent:contributor".freeze
    ITEM_DIMENSIONS       = %w(customEvent:dpla_id customEvent:item_title
                               customEvent:contributor).freeze

    COUNTED_EVENTS = "eventName=~^(#{EVENT_NAMES.values.join('|')})$".freeze

    def self.hub_filters(hub, contributor = nil)
      with_contributor([COUNTED_EVENTS, partner_filter(hub)], contributor)
    end

    def self.event_filters(event_name, hub, contributor = nil)
      with_contributor(["eventName==#{EVENT_NAMES.fetch(event_name)}", partner_filter(hub)],
                       contributor)
    end

    # "item_view" => "View Item". Anything else, such as "(other)", is nil.
    def self.event_name(value)
      EVENT_NAMES.key(value)
    end

    # [dpla_id, item_title, contributor, count] => [label, contributor, count]
    def self.item_row(row)
      id, title, *rest = row
      ["#{id} : #{title}", *rest]
    end

    def self.partner_filter(hub)
      "customEvent:partner==#{hub.to_s[0, PARAM_VALUE_MAX]}"
    end

    def self.with_contributor(filters, contributor)
      filters << "customEvent:contributor==#{contributor[0, PARAM_VALUE_MAX]}" if contributor
      filters
    end
    private_class_method :partner_filter, :with_contributor
  end
end
