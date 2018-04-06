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
      get "/admin/users/1/edit"
      expect(response).to redirect_to(admin_user_path(user))
    end
  end
end
