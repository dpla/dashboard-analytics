require 'rails_helper'

describe "timelines routing", type: :routing do

  it "routes /hubs/foo/timelines to timelines#index" do
    expect(get: "hubs/foo/timelines").to route_to(
      controller: "timelines",
      action: "index",
      hub_id: "foo"
    )
  end

  it "routes /hubs/foo/contributors/bar/timelines to timelines#index" do
    expect(get: "hubs/foo/contributors/bar/timelines").to route_to(
      controller: "timelines",
      action: "index",
      hub_id: "foo",
      contributor_id: "bar"
    )
  end
end
