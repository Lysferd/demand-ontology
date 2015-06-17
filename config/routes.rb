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

  controller :datasets do
    get 'new_individual/:id' => :new_individual, as: 'new_individual'
    post 'create_individual' => :create_individual

    get 'edit_individual/:id/:name' => :edit_individual, as: 'edit_individual'
    post 'update_individual' => :update_individual

    delete 'destroy_individual/:id/:name' => :destroy_individual, as: 'destroy_individual'
  end


  # -=-=-=-=-
  # Define AJAX Requests:
  get 'datasets/:id/send_rdf_source', to: 'datasets#send_rdf_source', as: 'send_rdf_source'
  put 'add_property', to: 'datasets#add_property'

  # -=-=-=-=-
  # Define ROOT Route:
  root to: 'home#index'
end
