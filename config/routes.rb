Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      resource :settings, only: [ :show, :update ]

      resources :boards, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          get :status
        end
      end

      resources :tasks, only: [ :index, :show, :create, :update, :destroy ] do
        collection do
          get :next
          get :pending_attention
          get :recurring
          get :errored_count
          post :spawn_ready
        end
        member do
          patch :complete
          post :agent_complete
          patch :claim
          patch :unclaim
          patch :assign
          patch :unassign
          patch :move
          get :agent_log
          get :session_health
          post :generate_followup
          post :enhance_followup
          post :create_followup
          post :handoff
          post :link_session
        end
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

  # Boards (multi-board kanban views)
  resources :boards, only: [ :index, :show, :create, :update, :destroy ] do
    patch :update_task_status, on: :member
    resources :tasks, only: [ :show, :new, :create, :edit, :update, :destroy ], controller: "boards/tasks" do
      member do
        patch :assign
        patch :unassign
        patch :move
        patch :move_to_board
        get :followup_modal
        get :handoff_modal
        post :generate_followup
        post :enhance_followup
        post :create_followup
        post :handoff
      end
    end
  end

  # Redirect root board path to first board
  get "board", to: redirect { |params, request|
    # This will be handled by the controller for proper user scoping
    "/boards"
  }
  get "pages/home"
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
