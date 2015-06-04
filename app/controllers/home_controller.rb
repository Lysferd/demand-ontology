class HomeController < ApplicationController

  skip_before_action :require_authentication, only: [ :login, :create_session ]

  def index
    # Empty Page.
    # Used for Debugging.
  end

  def login
    redirect_to( datasets_path ) if cookies[:auth_token]
  end

  def create_session
    if user = User::authenticate( params[:email], params[:password] )
      if params[:remember]
        cookies.permanent[:auth_token] = user.auth_token
      else
        cookies[:auth_token] = user.auth_token
      end
      redirect_to( datasets_path )
    else
      redirect_to( login_path )
    end
  end

  def destroy_session
    reset_session
    cookies.delete( :auth_token )
    redirect_to( login_path )
  end

  def query
    @datasets = Dataset::where( user_id: current_user.id )
  end

  def query_results
    if params[:dataset_id].empty?
      redirect_to query_path, notice: "Nenhuma ontologia selecionada."
      return
    end

    dataset = Dataset::find_by_id( params[:dataset_id] )
    @results = dataset.query_to_array( params[:query] )
    @query = params[:query]
  end

end
