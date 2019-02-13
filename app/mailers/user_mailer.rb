# Password reset base on Devise::Models::Recoverable
# https://github.com/plataformatec/devise/blob/715192a7709a4c02127afb067e66230061b82cf2/lib/devise/models/recoverable.rb

class UserMailer < ApplicationMailer

  def welcome_email
    @user = params[:user]

    raw, enc = Devise.token_generator.generate(User, :reset_password_token)
    @user.reset_password_token = enc
    @user.reset_password_sent_at = Time.now.utc
    @user.save

    @token = raw

    mail(to: @user.email, subject: 'Welcome to DPLA Analytics Dashboard')
  end
end
