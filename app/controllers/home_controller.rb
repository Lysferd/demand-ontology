# Encoding: UTF-8

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
    user = User::authenticate(params[:email], params[:password])
    if user
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

  def reasoner
    @datasets = Dataset::all
  end

  def reasoner_inferences
    if params[:dataset_id].empty? or params[:individual_name].empty?
      redirect_to( reasoner_path, notice: 'Nenhum dataset/indivíduo foi selecionado.' )
    end

    dataset = Dataset::find_by_id( params[:dataset_id] )
    @dataset_name = dataset.name
    @individual_name = params[:individual_name]

    @inferences = dataset.reason( params[:individual_name] )
  end

  def refresh_individual_list
    @individuals = Dataset::find_by_id( params[:dataset_id] ).individuals
  end

  def query
    @datasets = Dataset::where( user_id: current_user.id )
  end

  def query_results
    if params[:dataset_id].empty?
      redirect_to( query_path, notice: 'Nenhuma ontologia selecionada.' )
      return
    end

    dataset = Dataset::find_by_id( params[:dataset_id] )
    @results = dataset.query_to_array( params[:query] )
    @query = params[:query]
  end

end
