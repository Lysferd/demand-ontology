Rails.application.routes.draw do

  # -=-=-=-=-
  # Define Resources:
  resources :datasets
  resources :users

  # -=-=-=-=-
  # Define HTTP GET/POST Routes:
  get 'home/index'
  get 'home/query'
  post 'home/query_results'
  get 'datasets/create_individual/:id', to: 'datasets#create_individual', as: 'create_individual'

  # -=-=-=-=-
  # Define AJAX Requests:
  get 'datasets/:id/send_rdf_source', to: 'datasets#send_rdf_source', as: 'send_rdf_source'

  # -=-=-=-=-
  # Define ROOT Route:
  root to: 'home#index'
end
