Rails.application.routes.draw do
  root 'pages#index'

  resources :sessions
  get 'login' => 'sessions#new'
  get 'logout' => 'sessions#destroy'
  get 'login/complete' => 'sessions#complete'

  # client side routes
  get '/settings' => 'pages#index'
  get '/f/*path' => 'pages#index'
  get '/t/:slug/:id' => 'pages#index', as: 'thread'

  # When you uncomment this, remove ApplicationHelper#post_url
  #get '/t/:slug/:thread_id/:id' => 'pages#index', as: 'post'

  namespace :api, format: false, defaults: {format: 'json'} do
    resources :users do
      get :me, on: :collection
    end

    resources :notifications do
      post :read, on: :collection, to: :read_all
      post :read, on: :member
    end

    resource :settings

    shallow do
      resources :subforum_groups do
        resources :subforums do
          post :subscribe, on: :member
          post :unsubscribe, on: :member

          resources :threads do
            post :subscribe, on: :member
            post :unsubscribe, on: :member
            resources :posts
          end
        end
      end
    end

    namespace :private do
      post :reply, to: 'email_replies#reply'
    end
  end
end
