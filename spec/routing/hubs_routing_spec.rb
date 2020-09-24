require 'rails_helper'

describe "hubs routing", type: :routing do

  it "routes /hubs to hubs#index" do
    expect(get: "/hubs").to route_to(
      controller: "hubs",
      action: "index"
    )
  end

  it "routes /hubs/foo to hubs#show for foo" do
    expect(get: "hubs/foo").to route_to(
      controller: "hubs",
      action: "show",
      id: "foo"
    )
  end

  it "handles dots in hub ids" do
    expect(get: "hubs/foo.bar").to route_to(
      controller: "hubs",
      action: "show", 
      id: "foo.bar"
    )
  end

  it "routes /hubs/foo/website_overview for foo" do
    expect(get: "hubs/foo/website_overview").to route_to(
      controller: "hubs",
      action: "website_overview",
      hub_id: "foo"
    )
  end

  it "routes /hubs/foo/api_overview for foo" do
    expect(get: "hubs/foo/api_overview").to route_to(
      controller: "hubs",
      action: "api_overview",
      hub_id: "foo"
    )
  end

  it "routes /hubs/foo/bws_overview for foo" do
    expect(get: "hubs/foo/bws_overview").to route_to(
      controller: "hubs",
      action: "bws_overview",
      hub_id: "foo"
    )
  end

  it "routes /hubs/foo/item_count for foo" do
    expect(get: "hubs/foo/item_count").to route_to(
      controller: "hubs",
      action: "item_count",
      hub_id: "foo"
    )
  end

  it "routes /hubs/foo/metadata_completeness for foo" do
    expect(get: "hubs/foo/metadata_completeness").to route_to(
      controller: "hubs",
      action: "metadata_completeness",
      hub_id: "foo"
    )
  end

  it "routes /hubs/foo/wikimedia_overview for foo" do
    expect(get: "hubs/foo/wikimedia_overview").to route_to(
      controller: "hubs",
      action: "wikimedia_overview",
      hub_id: "foo"
    )
  end
end
