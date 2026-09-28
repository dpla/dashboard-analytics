# Source set views. The rows already carry the contributor, and the set
# slugs come from the counted paths, so neither needs a lookup.
class PssEventsPresenter < WebsiteEventsPresenter
  private

  def contributor_lookup(_page_rows)
    {}
  end

  def membership_lookup
    @ga_response.memberships
  end
end
