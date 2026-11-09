require "rails_helper"

# The timelines and user locations pages embedded a GA access token in their
# HTML. They are gone; old bookmarks redirect to the matching overview.
RSpec.describe "Retired pages", type: :request do

  def expect_redirect_to(path)
    expect(response).to have_http_status(:moved_permanently)
    expect(URI(response.location).request_uri).to eq(path)
  end

  it "redirects hub timelines to the hub overview, keeping dates" do
    get "/hubs/foo/timelines/website?start_date=2025-08&end_date=2025-09&page=2"
    expect_redirect_to("/hubs/foo?end_date=2025-09&start_date=2025-08")
  end

  it "redirects hub locations to the hub overview" do
    get "/hubs/Digital%20Commonwealth/locations"
    expect_redirect_to("/hubs/Digital%20Commonwealth")
  end

  it "redirects contributor timelines and locations to the contributor overview" do
    get "/hubs/foo/contributors/bar/timelines/api"
    expect_redirect_to("/hubs/foo/contributors/bar")

    get "/hubs/foo/contributors/bar/locations"
    expect_redirect_to("/hubs/foo/contributors/bar")
  end

  it "keeps slashes in hub names encoded the way route_id does" do
    get "/hubs/NJ%252FDE%20Digital%20Collective/locations"
    expect_redirect_to("/hubs/NJ%252FDE%20Digital%20Collective")
  end
end
