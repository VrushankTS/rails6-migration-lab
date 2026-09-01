Rails.application.routes.draw do
  resources :posts, only: %i[index show new create]

  root "posts#index"
end
