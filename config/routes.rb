Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      resources :tasks, only: [ :index, :show, :create, :update, :destroy ] do
        collection do
          get :next
        end
        member do
          patch :complete
          patch :claim
          patch :unclaim
        end
        resources :comments, only: [ :index, :create ]
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

  # Kanban Board (main authenticated view)
  resource :board, only: [ :show ], controller: "board" do
    patch :update_task_status
    resources :tasks, only: [ :show, :new, :create, :edit, :update, :destroy ], controller: "board/tasks" do
      resources :comments, only: [ :create ], controller: "board/comments"
    end
  end
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
