require 'rails_helper'

describe "locations routing", type: :routing do

  it "routes /hubs/foo/locations to locations#index" do
    expect(get: "hubs/foo/locations").to route_to(
      controller: "locations",
      action: "index",
      hub_id: "foo"
    )
  end

  it "routes /hubs/foo/contributors/bar/locations to locations#index" do
    expect(get: "hubs/foo/contributors/bar/locations").to route_to(
      controller: "locations",
      action: "index",
      hub_id: "foo",
      contributor_id: "bar"
    )
  end
end
