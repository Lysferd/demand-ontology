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

  get 'datasets/new_individual/:id',
    to: 'datasets#new_individual',
    as: 'new_individual'

  post 'create_individual' => 'datasets#create_individual'

  # -=-=-=-=-
  # Define AJAX Requests:
  get 'datasets/:id/send_rdf_source', to: 'datasets#send_rdf_source', as: 'send_rdf_source'
  put 'add_property', to: 'datasets#add_property'

  # -=-=-=-=-
  # Define ROOT Route:
  root to: 'home#index'
end
