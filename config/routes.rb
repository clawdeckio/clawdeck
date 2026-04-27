Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      resource :settings, only: [ :show, :update ]

      resources :agents, only: [ :index, :show, :update ] do
        collection do
          post :register
        end

        member do
          post :heartbeat
          post :commands, to: "agent_commands#enqueue"
        end
      end

      resources :agent_commands, only: [] do
        collection do
          get :next, to: "agent_commands#next"
        end

        member do
          patch :ack, to: "agent_commands#ack"
          patch :complete, to: "agent_commands#complete"
        end
      end

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
      end
    end
  end

  namespace :admin do
    root to: "dashboard#index"
    resources :users, only: [ :index ]
  end

  resources :agents, only: [ :index, :show ] do
    resources :commands, only: [ :create ], controller: "agent_commands"
  end

  resource :session, only: [:new, :create, :destroy]
  resource :registration, only: [:new, :create]
  get "/auth/:provider/callback", to: "omniauth_callbacks#github", as: :omniauth_callback
  get "/auth/failure", to: "omniauth_callbacks#failure"
  resources :passwords, param: :token
  resource :settings, only: [ :show, :update ], controller: "profiles" do
    post :regenerate_api_token
  end

  # Boards (multi-board kanban views)
  resources :boards, only: [ :index, :show, :create, :update, :destroy ] do
    patch :update_task_status, on: :member
    resources :tasks, only: [ :show, :new, :create, :edit, :update, :destroy ], controller: "boards/tasks" do
      member do
        patch :assign
        patch :unassign
      end
      resources :subtasks, only: [ :create, :update, :destroy ], controller: "boards/subtasks"
    end
  end

  # Redirect root board path to first board
  get "board", to: redirect { |params, request|
    # This will be handled by the controller for proper user scoping
    "/boards"
  }
  # Agent chat endpoint
  post "agent/chat", to: "agent#chat"

  # Home dashboard (authenticated users)
  get "home", to: "home#show", as: :home

  get "pages/home"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root: landing page for visitors, dashboard for logged-in users
  root "pages#home"
end
