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
end
