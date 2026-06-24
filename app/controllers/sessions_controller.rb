class SessionsController < ApplicationController
  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    SessionMailer.magic_link(user).deliver_later if user
    redirect_to admin_path, notice: 'Check your email for a sign-in link.'
  end

  def verify
    user = User.find_by_token_for(:magic_link, params[:token])
    if user
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: 'Signed in.'
    else
      redirect_to admin_path, alert: 'That sign-in link is invalid or expired.'
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: 'Signed out.'
  end
end
