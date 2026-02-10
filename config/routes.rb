Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      resource :settings, only: [ :show, :update ]

      resources :agents, only: [ :index, :show, :create, :update, :destroy ]

      resources :activities, only: [ :index, :show ]

      # Aggregated activity feed (tasks/comments/artifacts)
      get :live_feed, to: "live_feed#index"

      resources :notifications, only: [ :index, :update ]

      resources :boards, only: [ :index, :show, :create, :update, :destroy ]

      resources :tasks, only: [ :index, :show, :create, :update, :destroy ] do
        collection do
          get :next
          get :pending_attention
        end
        member do
          patch :complete
          patch :claim
          patch :unclaim
          patch :assign
          patch :unassign
        end

        resources :comments, controller: "task_comments", only: [ :index, :show, :create, :update, :destroy ]
        resources :artifacts, controller: "task_artifacts", only: [ :index, :show, :create, :update, :destroy ]
        resources :activities, only: [ :index ], controller: "activities"
      end
    end
  end

  namespace :admin do
    root to: "dashboard#index"
    resources :users, only: [ :index ]
  end

  resource :session, only: [:new, :create, :destroy]
  resource :registration, only: [:new, :create]
  get "/auth/:provider/callback", to: "omniauth_callbacks#github", as: :omniauth_callback
  get "/auth/failure", to: "omniauth_callbacks#failure"
  resources :passwords, param: :token
  resource :settings, only: [ :show, :update ], controller: "profiles" do
    post :regenerate_api_token
  end
  resources :notifications, only: [] do
    member do
      patch :read
      patch :unread
    end
    collection do
      patch :read_all
    end
  end

  # Boards (multi-board kanban views)
  resources :boards, only: [ :index, :show, :create, :update, :destroy ] do
    patch :update_task_status, on: :member
    resources :tasks, only: [ :show, :new, :create, :edit, :update, :destroy ], controller: "boards/tasks" do
      member do
        patch :assign
        patch :unassign
      end
    end
  end

  # Redirect root board path to first board
  get "board", to: redirect { |params, request|
    # This will be handled by the controller for proper user scoping
    "/boards"
  }
  get "pages/home"
  get "health", to: "health#show"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"
end
