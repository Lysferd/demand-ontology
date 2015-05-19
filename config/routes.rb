Rails.application.routes.draw do

  resources :datasets
  resources :users

  # -=-=-=-=-
  # Define HTTP GET Routes:
  get 'home/index'
  get 'home/query'
  post 'home/query_results'

  post 'datasets/sparql'

  resources :users
  resources :datasets

  # -=-=-=-=-
  # Define ROOT Route:
  root to: 'home#index'
end
