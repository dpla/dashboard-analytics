require "rails_helper"

RSpec.describe "Hub management", :type => :request do

  let(:admin) { User.create(email: "admin@example.com",
                            password: "password",
                            password_confirmation: "password",
                            admin: true,
                            hub: "All") }

  let(:user_foo) { User.create(email: "userfoo@example.com",
                               password: "password",
                               password_confirmation: "password",
                               admin: false,
                               hub: "foo") }

  let(:user_bar) { User.create(email: "userbar@example.com",
                               password: "password",
                               password_confirmation: "password",
                               admin: false,
                               hub: "bar") }

  # Hub lookups stubbed so the suite runs without AWS credentials.
  before do
    allow(HubStats).to receive(:fetch).and_return(
      "hubs" => {
        "foo" => { "item_count" => 1, "contributors" => { "bat" => 1 } },
        "bar" => { "item_count" => 1, "contributors" => { "bat" => 1 } }
      }
    )
    allow(HubStats).to receive(:fetch_bws).and_return("hubs" => {})
  end

  context "user not logged in" do

    it "redirects index to login page" do
      get "/hubs"
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects show to login page" do
      get "/hubs/foo"
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "user with all hubs permission logged in" do

    before(:each) do
      sign_in admin
    end

    it "does not redirect index" do
      get "/hubs"
      expect(response).not_to have_http_status(302)
    end

    it "does not redirect show" do
      get "/hubs/foo"
      expect(response).not_to have_http_status(302)
    end
  end

  context "user with correct hub permission logged in" do
    before(:each) do
      sign_in user_foo
    end

    it "redirects index to show" do
      get "/hubs"
      expect(response).to redirect_to(hub_path('foo'))
    end

    it "does not redirect show" do
      get "/hubs/foo"
      expect(response).not_to have_http_status(302)
    end
  end

  context "user with incorrect hub permission logged in" do
    before(:each) do
      sign_in user_bar
    end

    it "redirects show to correct hub" do
      get "/hubs/foo"
      expect(response).to redirect_to(hub_path('bar'))
    end
  end
end
