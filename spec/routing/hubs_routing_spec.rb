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
end
