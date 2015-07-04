# Encoding: UTF-8

class HomeController < ApplicationController

  skip_before_action :require_authentication, only: [ :login, :create_session ]

  def login
    redirect_to( datasets_path ) if cookies[:auth_token]
  end

  def create_session
    user = User::authenticate(params[:email], params[:password])
    if user
      if params[:remember]
        cookies.permanent[:auth_token] = user.auth_token
      else
        cookies[:auth_token] = user.auth_token
      end
      redirect_to( params[:redirect] ? params[:redirect] : datasets_path )
    else
      redirect_to( login_path, alert: 'Não foi possível efetuar login: credenciais incorretas.' )
    end
  end

  def destroy_session
    reset_session
    cookies.delete( :auth_token )
    redirect_to( login_path )
  end

end
