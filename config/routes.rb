Rails.application.routes.draw do

  # -=-=-=-=-
  # Define Resources:
  resources :datasets
  resources :users

  # -=-=-=-=-
  # Define HTTP GET/POST Routes:
  controller :home do
    get 'index' => :index
    get 'query' => :query
    post 'query' => :query_results

    get 'login' => :login
    post 'login' => :create_session
    delete 'logout' => :destroy_session
  end

  get 'datasets/create_individual/:id',
    to: 'datasets#create_individual',
    as: 'create_individual'

  # -=-=-=-=-
  # Define AJAX Requests:
  get 'datasets/:id/send_rdf_source', to: 'datasets#send_rdf_source', as: 'send_rdf_source'

  # -=-=-=-=-
  # Define ROOT Route:
  root to: 'home#index'
end
