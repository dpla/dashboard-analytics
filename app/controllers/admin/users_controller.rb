module Admin
  class UsersController < ApplicationController

    def index
      @users = current_user.hub == "All" ? User.all : 
        User.where("hub = ?", current_user.hub)

      redirect_to admin_user_path(current_user) unless current_user.admin
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

      unless current_user.admin
        flash[:notice] = "You don't have permission to create a new user."
        redirect_to admin_user_path(current_user)
      end
    end

    def edit
      @user = User.find(params[:id])
      redirect_to admin_user_path(current_user) unless current_user.admin
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
      @user = User.find(params[:id])

      if @user.update(user_params)
        redirect_to admin_users_path
      else
        render 'edit'
      end
    end

    def destroy
      @user = User.find(params[:id])
      @user.destroy
      redirect_to admin_users_path
    end

    private

    def user_params
      params.require(:user).permit(:email,
                                   :admin,
                                   :hub,
                                   :password,
                                   :password_confirmation)
    end
  end
end
