require "rails_helper"

RSpec.describe "Contributor management", :type => :request do

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

  context "user not logged in" do

    it "redirects show to login page" do
      get "/hubs/foo/contributors/bat"
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "user with all hubs permission logged in" do

    before(:each) do
      sign_in admin
    end

    it "does not redirect show" do
      get "/hubs/foo/contributors/bat"
      expect(response).not_to have_http_status(302)
    end
  end

  context "user with correct hub permission logged in" do
    before(:each) do
      sign_in user_foo
    end

    it "does not redirect show" do
      get "/hubs/foo/contributors/bat"
      expect(response).not_to have_http_status(302)
    end
  end

  context "user with incorrect hub permission logged in" do
    before(:each) do
      sign_in user_bar
    end

    it "redirects to show for correct user" do
      get "/hubs/foo/contributors/bat"
      expect(response).to redirect_to(hub_path('bar'))
    end
  end
end
