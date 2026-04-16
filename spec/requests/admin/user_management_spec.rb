require "rails_helper"

RSpec.describe "User management", :type => :request do

  let(:admin) { User.create(email: "admin@example.com",
                            password: "password",
                            password_confirmation: "password",
                            admin: true,
                            hub: "All") }

  let(:user) { User.create(email: "user@example.com",
                           password: "password",
                           password_confirmation: "password",
                           admin: false,
                           hub: "foo") }

  context "user not logged in" do

    it "redirects index to login page" do
      get "/admin/users"
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects show to login page" do
      get "/admin/users/#{user.id}"
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects new to login page" do
      get "/admin/users/new"
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects edit to login page" do
      get "/admin/users/#{user.id}/edit"
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "user with admin permissions logged in" do

    before(:each) do
      sign_in admin
    end

    it "does not redirect index" do
      get "/admin/users"
      expect(response).not_to have_http_status(302)
    end

    it "does not redirect show for correct user" do
      get "/admin/users/#{admin.id}"
      expect(response).not_to have_http_status(302)
    end

    it "redirects incorrect show to correct show" do
      get "/admin/users/#{user.id}"
      expect(response).to redirect_to(admin_user_path(admin))
    end

    it "does not redirect new" do
      get "/admin/users/new"
      expect(response).not_to have_http_status(302)
    end

    it "does not redirect edit" do
      get "/admin/users/#{user.id}/edit"
      expect(response).not_to have_http_status(302)
    end
  end

  context "user with user permission logged in" do
    before(:each) do
      sign_in user
    end

    it "redirects index to show" do
      get "/admin/users"
      expect(response).to redirect_to(admin_user_path(user))
    end

    it "does not redirect show for correct user" do
      get "/admin/users/#{user.id}"
      expect(response).not_to have_http_status(302)
    end

    it "redirects incorrect show to correct show" do
      get "/admin/users/#{admin.id}"
      expect(response).to redirect_to(admin_user_path(user))
    end

    it "redirects new to show" do
      get "/admin/users/new"
      expect(response).to redirect_to(admin_user_path(user))
    end

    it "redirects edit to show" do
      get "/admin/users/#{user.id}/edit"
      expect(response).to redirect_to(admin_user_path(user))
    end
  end

  # Regression: hub-scoped admin cannot escalate a user's hub to "All".
  # This backs the Brakeman mass-assignment suppression in config/brakeman.ignore.
  context "hub-scoped admin (admin: true, hub: non-All)" do
    let(:hub_admin) { User.create!(email: "hubadmin@example.com",
                                   password: "password",
                                   password_confirmation: "password",
                                   admin: true,
                                   hub: "foo") }

    before(:each) do
      sign_in hub_admin
    end

    it "ignores a submitted hub value and locks create to the admin's own hub" do
      post "/admin/users", params: {
        user: { email: "newuser@example.com", hub: "All", admin: "false" }
      }
      created = User.find_by(email: "newuser@example.com")
      expect(created).not_to be_nil
      expect(created.hub).to eq(hub_admin.hub)
    end

    it "ignores a submitted hub value and locks update to the admin's own hub" do
      new_email = "updated@example.com"
      patch "/admin/users/#{user.id}", params: {
        user: { email: new_email, hub: "All", admin: "false" }
      }
      user.reload
      expect(user.email).to eq(new_email)
      expect(user.hub).to eq(hub_admin.hub)
    end
  end
end
