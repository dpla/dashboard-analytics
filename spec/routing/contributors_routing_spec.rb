require 'rails_helper'

describe "contributors routing", type: :routing do

  it "routes /hubs/hname/contributors/cname to contributors#show for cname" do
    expect(get: "hubs/hname/contributors/cname").to route_to(
      controller: "contributors",
      action: "show",
      hub_id: "hname",
      id: "cname"
    )
  end
end
