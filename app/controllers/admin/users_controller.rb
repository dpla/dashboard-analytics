module Admin
  class UsersController < ApplicationController
    before_action :require_admin!, except: [:show]

    def index
      @users = manageable_users
    end

    def show
      @user = User.find(params[:id])

      if @user.email != current_user.email
        flash[:notice] = "You don't have access to that user profile."
        redirect_to admin_user_path(current_user)
      end
    end

    def new
      @user = User.new
    end

    def edit
      @user = manageable_users.find(params[:id])
    end

    def create
      generated_password = Devise.friendly_token.first(8)
      create_params = user_params
      create_params[:password] = generated_password
      create_params[:password_confirmation] = generated_password

      @user = User.new(create_params)

      if @user.save
        UserMailer.with(user: @user).welcome_email.deliver
        flash[:notice] = "User #{@user.email} was successfully created."
        redirect_to admin_users_path
      else
        render 'new'
      end
    end

    def update
      @user = manageable_users.find(params[:id])

      if @user.update(user_params)
        redirect_to admin_users_path
      else
        render 'edit'
      end
    end

    def destroy
      @user = manageable_users.find(params[:id])
      email = @user.email

      if @user.destroy
        flash[:notice] = "User #{email} was successfully deleted."
      else
        flash[:alert] = "Could not delete user #{email}."
      end

      redirect_to admin_users_path
    end

    def send_password_reset
      @user = manageable_users.find(params[:id])
      @user.send_reset_password_instructions
      flash[:notice] = "Password reset instructions sent to #{@user.email}."
      redirect_to admin_users_path
    end

    private

    def manageable_users
      admin_for_all_hubs? ? User.all : User.where(hub: current_user.hub)
    end

    def user_params
      permitted = params.require(:user).permit(:email,
                                               :admin,
                                               :hub,
                                               :password,
                                               :password_confirmation)
      # Hub-scoped admins may only create/edit users within their own hub.
      # Override any submitted hub value and disallow escalation to "All".
      unless admin_for_all_hubs?
        permitted[:hub] = current_user.hub
      end
      permitted
    end
  end
end
