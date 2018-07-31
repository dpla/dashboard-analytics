require 'rails_helper'

describe "timelines routing", type: :routing do

  it "routes /hubs/foo/timelines/website to timelines#show" do
    expect(get: "hubs/foo/timelines/website").to route_to(
      controller: "timelines",
      action: "show",
      hub_id: "foo",
      id: "website"
    )
  end

  it "routes /hubs/foo/contributors/bar/timelines/api to timelines#show" do
    expect(get: "hubs/foo/contributors/bar/timelines/api").to route_to(
      controller: "timelines",
      action: "show",
      hub_id: "foo",
      contributor_id: "bar",
      id: "api"
    )
  end
end
