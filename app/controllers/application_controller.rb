class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :assert_user_existence
  before_action :require_authentication

  def current_user
    User::find_by_auth_token( cookies[:auth_token] ) if cookies[:auth_token]
  end
  helper_method :current_user

  private
  def assert_user_existence
    return unless User::count.zero?
    redirect_to( new_user_path )
  end

  def require_authentication
    return if User::count.zero?
    return if cookies[:auth_token]

    if request.url == root_url or request.url == login_url
      redirect_to login_path
    else
      redirect_to login_path( redirect: request.url ),
                  alert: 'Favor efetuar login.'
    end
  end
end