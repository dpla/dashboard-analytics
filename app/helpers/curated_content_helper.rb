module CuratedContentHelper

  CURATED_PAGE_URLS = {
    exhibitions: "https://dp.la/exhibitions",
    primary_source_sets: "https://dp.la/primary-source-sets",
  }.freeze

  ##
  # Which exhibitions or primary source sets hold the institution's items,
  # as { slug => item count }
  # nil when the API call failed
  #
  # @param target [Hub|Contributor]
  # @param kind [Symbol] :exhibitions or :primary_source_sets
  #
  def curated_breakdown_for(target, kind)
    hub, contributor = target.is_a?(Hub) ?
      [target.name, nil] : [target.hub.name, target.name]

    @curated_breakdowns ||= {}
    key = [kind, hub, contributor]
    @curated_breakdowns.fetch(key) do
      @curated_breakdowns[key] =
        DplaApiResponseBuilder.new.curated_breakdown(kind, hub, contributor)
    end
  end

  # Fails open: an API failure counts as participation, so links never
  # wrongly disable.
  def curated_participant?(target, kind)
    breakdown = curated_breakdown_for(target, kind)
    breakdown.nil? || breakdown.any?
  end

  def curated_page_url(kind, slug)
    "#{CURATED_PAGE_URLS.fetch(kind)}/#{slug}"
  end

  def curated_noun(kind, count)
    noun = kind == :exhibitions ? "exhibition" : "primary source set"
    count == 1 ? noun : noun.pluralize
  end
end
