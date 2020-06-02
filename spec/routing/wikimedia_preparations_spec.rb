require 'rails_helper'

describe "wikimedia preparations routing", type: :routing do

  it "routes /hubs/foo/wikimedia_preparations to wikimedia_preparations#index" do
    expect(get: "hubs/foo/wikimedia_preparations").to route_to(
      controller: "wikimedia_preparations",
      action: "index",
      hub_id: "foo"
    )
  end

  it "routes /hubs/foo/contributors/bar/wikimedia_preparations to wikimedia_preparations#index" do
    expect(get: "hubs/foo/contributors/bar/wikimedia_preparations").to route_to(
      controller: "wikimedia_preparations",
      action: "index",
      hub_id: "foo",
      contributor_id: "bar"
    )
  end
end
