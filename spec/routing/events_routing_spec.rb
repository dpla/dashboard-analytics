require 'rails_helper'

describe "events routing", type: :routing do

  it "routes /hubs/foo/events/bat to events#show" do
    expect(get: "hubs/foo/events/bat").to route_to(
      controller: "events",
      action: "show",
      hub_id: "foo",
      id: "bat"
    )
  end

  it "routes /hubs/foo/contributors/bar/events/bat to events#show" do
    expect(get: "hubs/foo/contributors/bar/events/bat").to route_to(
      controller: "events",
      action: "show",
      hub_id: "foo",
      contributor_id: "bar",
      id: "bat"
    )
  end
end
