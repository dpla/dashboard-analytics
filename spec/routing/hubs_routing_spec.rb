require 'rails_helper'

describe "hubs routing", type: :routing do

  it "routes /hubs to hubs#index" do
    expect(get: "/hubs").to route_to(
      controller: "hubs",
      action: "index"
    )
  end

  it "routes /hubs/hubname to hubs#show for hubname" do
    expect(get: "hubs/hubname").to route_to(
      controller: "hubs",
      action: "show",
      id: "hubname"
    )
  end
end
