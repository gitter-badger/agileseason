class SessionsController < ApplicationController
  skip_before_action :authenticate, only: [:create, :destroy]

  def create
    user = find_user || create_user
    create_session_for(user)
    if session[:return_url]
      redirect_to session[:return_url]
      session[:return_url] = nil
    else
      redirect_to boards_url
    end
  end

  def destroy
    destroy_session
    redirect_to root_url
  end

  private

  def find_user
    User.where(github_username: github_username_auth).first
  end

  def create_user
    user = User.create!(
      github_username: github_username_auth,
      email: github_email_address_auth,
      utm: {
        source: cookies[:source],
        medium: cookies[:medium],
        campaign: cookies[:campaign]
      }
    )

    ui_event :registration
    MixpanelTracker.new.link_user(user, session[:guest_id])

    user
  end

  def create_session_for(user)
    session[:remember_token] = user.remember_token
    session[:github_token] = github_token_auth
  end

  def destroy_session
    session[:remember_token] = nil
    session[:github_token] = nil
  end

  def github_username_auth
    request.env['omniauth.auth']['info']['nickname']
  end

  def github_email_address_auth
    request.env['omniauth.auth']['info']['email']
  end

  def github_token_auth
    request.env['omniauth.auth']['credentials']['token']
  end
end
