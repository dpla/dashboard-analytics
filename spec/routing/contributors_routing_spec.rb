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

  it "routes /hubs/foo/contributors/bar/contributor_website_overview for bar" do
    expect(get: "hubs/foo/contributors/bar/contributor_website_overview").to route_to(
      controller: "contributors",
      action: "contributor_website_overview",
      hub_id: "foo",
      contributor_id: "bar"
    )
  end

  it "routes /hubs/foo/contributors/bar/contributor_api_overview for bar" do
    expect(get: "hubs/foo/contributors/bar/contributor_api_overview").to route_to(
      controller: "contributors",
      action: "contributor_api_overview",
      hub_id: "foo",
      contributor_id: "bar"
    )
  end

  it "routes /hubs/foo/contributors/bar/contributor_item_count for bar" do
    expect(get: "hubs/foo/contributors/bar/contributor_item_count").to route_to(
      controller: "contributors",
      action: "contributor_item_count",
      hub_id: "foo",
      contributor_id: "bar"
    )
  end

  it "routes /hubs/foo/contributors/bar/contributor_metadata_completeness for bar" do
    expect(get: "hubs/foo/contributors/bar/contributor_metadata_completeness").to route_to(
      controller: "contributors",
      action: "contributor_metadata_completeness",
      hub_id: "foo",
      contributor_id: "bar"
    )
  end

  it "routes /hubs/foo/contributors/bar/contributor_wikimedia_overview for bar" do
    expect(get: "hubs/foo/contributors/bar/contributor_wikimedia_overview").to route_to(
      controller: "contributors",
      action: "contributor_wikimedia_overview",
      hub_id: "foo",
      contributor_id: "bar"
    )
  end
end
