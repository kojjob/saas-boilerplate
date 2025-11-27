Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # ==================================
  # Authentication Routes
  # ==================================
  get "sign_in", to: "sessions#new", as: :sign_in
  post "sign_in", to: "sessions#create"
  delete "sign_out", to: "sessions#destroy", as: :sign_out

  get "sign_up", to: "registrations#new", as: :sign_up
  post "sign_up", to: "registrations#create"

  # Password reset
  resources :password_resets, only: [ :new, :create, :edit, :update ], param: :token

  # Email confirmation
  get "confirm_email/:token", to: "confirmations#show", as: :confirm_email
  resources :confirmations, only: [ :new, :create ]

  # OAuth callbacks
  get "auth/:provider/callback", to: "oauth_callbacks#create"
  get "auth/failure", to: "oauth_callbacks#failure"

  # ==================================
  # Account Management Routes
  # ==================================
  resource :account, only: [ :show, :edit, :update ] do
    member do
      get :billing
      post :switch, to: "accounts#switch"
    end

    # Team members management
    resources :members, only: [ :index, :update, :destroy ], controller: "members" do
      member do
        delete :leave, to: "members#leave"
      end
    end

    # Invitations (sent by admins/owners)
    resources :invitations, only: [ :new, :create, :destroy ], controller: "invitations" do
      member do
        post :resend
      end
    end
  end

  # ==================================
  # Public Invitation Acceptance
  # ==================================
  get "invitations/:token/accept", to: "invitation_acceptances#show", as: :accept_invitation
  post "invitations/:token/accept", to: "invitation_acceptances#create"

  # ==================================
  # Billing Routes
  # ==================================
  get "billing", to: "billing#index", as: :billing
  get "billing/portal", to: "billing#portal", as: :billing_portal
  post "billing/checkout", to: "billing#checkout", as: :billing_checkout
  get "billing/success", to: "billing#success", as: :billing_success
  get "billing/cancel", to: "billing#cancel", as: :billing_cancel

  # Pay webhook for Stripe events
  post "pay/webhooks/stripe", to: "pay/webhooks/stripe#create"

  # ==================================
  # Dashboard
  # ==================================
  get "dashboard", to: "dashboard#show", as: :dashboard

  # ==================================
  # Health Check
  # ==================================
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
