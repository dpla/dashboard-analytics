require 'rails_helper'

describe "admin/users routing", type: :routing do

  it "routes /admin/users to admin/users#index" do
    expect(get: "admin/users").to route_to(
      controller: "admin/users",
      action: "index"
    )
  end

  it "routes /admin/users/foo to admin/users#show for foo" do
    expect(get: "admin/users/foo").to route_to(
      controller: "admin/users",
      action: "show",
      id: "foo"
    )
  end

  it "routes /admin/users/new to admin/users#new" do
    expect(get: "admin/users/new").to route_to(
      controller: "admin/users",
      action: "new"
    )
  end

  it "routes /admin/users/foo/edit to admin/users#edit for foo" do
    expect(get: "admin/users/foo/edit").to route_to(
      controller: "admin/users",
      action: "edit",
      id: "foo"
    )
  end

  it "routes POST /admin/users to admin/users#create" do
    expect(post: "admin/users").to route_to(
      controller: "admin/users",
      action: "create"
    )
  end

  it "routes PUT /admin/users/foo to admin/users#update for foo" do
    expect(put: "admin/users/foo").to route_to(
      controller: "admin/users",
      action: "update",
      id: "foo"
    )
  end

  it "routes PATCH /admin/users/foo to admin/users#update for foo" do
    expect(patch: "admin/users/foo").to route_to(
      controller: "admin/users",
      action: "update",
      id: "foo"
    )
  end

  it "routes DELETE /admin/users/foo to admin/users#destroy for foo" do
    expect(delete: "admin/users/foo").to route_to(
      controller: "admin/users",
      action: "destroy",
      id: "foo"
    )
  end
end
