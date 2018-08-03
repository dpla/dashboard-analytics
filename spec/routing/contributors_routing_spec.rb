require 'rails_helper'

describe "contributors routing", type: :routing do

  it "routes /hubs/foo/contributors to contributors#index" do
    expect(get: "hubs/foo/contributors/").to route_to(
      controller: "contributors",
      action: "index",
      hub_id: "foo"
    )
  end

  it "routes /hubs/foo/contributors/bar to contributors#show for bar" do
    expect(get: "hubs/foo/contributors/bar").to route_to(
      controller: "contributors",
      action: "show",
      hub_id: "foo",
      id: "bar"
    )
  end

  it "handles dots in contributor ids" do
    expect(get: "hubs/foo/contributors/bar.bat").to route_to(
      controller: "contributors",
      action: "show",
      hub_id: "foo",
      id: "bar.bat"
    )
  end

  it "routes /hubs/foo/contributors/bar/contributors_website_overview for bar" do
    expect(get: "hubs/foo/contributors/bar/contributors_website_overview").to route_to(
      controller: "contributors",
      action: "contributors_website_overview",
      hub_id: "foo",
      contributor_id: "bar"
    )
  end
end
