module Admin
  class UsersController < ApplicationController

    def index
      @users = User.all
      redirect_to admin_user_path(current_user) unless current_user.admin
    end

    def show
      @user = User.find(params[:id])

      if current_user.admin
        redirect_to admin_users_path
      elsif @user.email != current_user.email
        redirect_to admin_user_path(current_user)
      end
    end

    def new
      @user = User.new
      redirect_to admin_user_path(current_user) unless current_user.admin
    end

    def edit
      @user = User.find(params[:id])
      redirect_to admin_user_path(current_user) unless current_user.admin
    end

    def create
      @user = User.new(user_params)

      if @user.save
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
