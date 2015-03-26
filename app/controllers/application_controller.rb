class ApplicationController < ActionController::Base
  include ApplicationHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :authenticate
  helper_method :current_user, :signed_in?

  unless Rails.env.test?
    rescue_from Exception, with: :runtime_error
    rescue_from SyntaxError, with: :runtime_error
    rescue_from NoMethodError, with: :runtime_error
    rescue_from ActionController::RoutingError, with: :runtime_error
    rescue_from AbstractController::ActionNotFound, with: :runtime_error
    rescue_from ActionView::Template::Error, with: :runtime_error
  end

  def runtime_error(e)
    raise e if remote_addr == '127.0.0.1' || !Rails.env.production?

    logger.error(e.message)
    logger.error(e.backtrace.join('\n'))

    if [
        ActionController::RoutingError,
        ActiveRecord::RecordNotFound,
        AbstractController::ActionNotFound,
        ActiveSupport::MessageVerifier::InvalidSignature
      ].include?(e.class)
      render file: 'public/404.html', status: 404, layout: false
    else
      render file: 'public/500.html', status: 503, layout: false
    end
  end

  private

  def authenticate
    redirect_to root_url unless signed_in?
    # FIX : Find best place for this.
    current_user.github_api = github_api
  end

  def signed_in?
    current_user.present?
  end

  def current_user
    @current_user ||= User.where(remember_token: session[:remember_token]).first
  end

  # FIX : Nees specs.
  def fetch_board
    @board ||= Board.find_by(github_name: params[:github_name] || params[:board_github_name])
    authorize!(:read, @board)
    # FIX : Keep @board or @board_bag after experiment.
    @board_bag = BoardBag.new(github_api, @board)
  end

  def fetch_board_for_update
    fetch_board
    authorize!(:update, @board)
  end

  def remote_addr
    request.headers['HTTP_X_FORWARDED_FOR'] ||
      request.headers['HTTP_X_REAL_IP'] ||
      request.headers['REMOTE_ADDR']
  end
end
