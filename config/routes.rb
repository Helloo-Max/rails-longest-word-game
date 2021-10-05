Rails.application.routes.draw do
  root to: 'games#new' #=> Get verb by default.

  get 'new', to: 'games#new'
  post 'score', to: 'games#score'
end
