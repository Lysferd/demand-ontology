Rails.application.routes.draw do

  # -=-=-=-=-
  # Define Resources
  resources :datasets
  resources :users

  # -=-=-=-=-
  # Define HTTP GET Routes:
  get 'home/index'
  get 'home/query'
  post 'home/query_results'
  get 'datasets/create_individual/:id', to: 'datasets#create_individual', as: 'create_individual'

  # -=-=-=-=-
  # Define ROOT Route:
  root to: 'home#index'
end
