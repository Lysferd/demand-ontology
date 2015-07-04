Rails.application.routes.draw do

  # -=-=-=-=-
  # Define Resources:
  resources :datasets
  resources :users

  # -=-=-=-=-
  # Define HTTP GET/POST Routes:
  controller :home do
    get 'index' => :index
    get 'ontograf' => :ontograf

    get 'login' => :login
    post 'login' => :create_session
    delete 'logout' => :destroy_session
  end

  controller :datasets do
    # -=-=-=-=-
    # Define routes for Feeders:
    get 'new_feeder/:id'              => :new_feeder, as: :new_feeder
    get 'edit_feeder/:id/:name'       => :edit_feeder, as: :edit_feeder
    get 'show_feeder/:id/:name'       => :show_feeder, as: :show_feeder
    post 'create_feeder'              => :create_feeder
    post 'update_feeder'              => :update_feeder
    delete 'destroy_feeder/:id/:name' => :destroy_feeder, as: :destroy_feeder

    # -=-=-=-=-
    # Define routes for Building Systems:
    get 'new_building_system/:id'              => :new_building_system, as: :new_building_system
    get 'edit_building_system/:id/:name'       => :edit_building_system, as: :edit_building_system
    get 'show_building_system/:id/:name'       => :show_building_system, as: :show_building_system
    post 'create_building_system'              => :create_building_system
    post 'update_building_system'              => :update_building_system
    delete 'destroy_building_system/:id/:name' => :destroy_building_system, as: :destroy_building_system

    # -=-=-=-=-
    # Define routes for Resources (AJAX)
    get 'new_resource'        => :new_resource
    post 'create_resource'    => :create_resource
    delete 'destroy_resource' => :destroy_resource

    # -=-=-=-=-
    # Define routes for querying:
    get 'query/:id'  => :query, as: :query
    post 'query/:id' => :query_results

    # -=-=-=-=-
    # Define routes for reasoning:
    #get 'reasoner/:id' => :reasoner, as: :reasoner
    get 'reasoner/:id/:name' => :reasoner_inferences, as: :reasoner
  end

  # -=-=-=-=-
  # Define AJAX Requests:
  get 'datasets/:id/send_rdf_source', to: 'datasets#send_rdf_source', as: :send_rdf_source

  put 'add_property', to: 'datasets#add_property'

  # -=-=-=-=-
  # Define ROOT Route:
  root to: 'datasets#index'
end
