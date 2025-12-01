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
    resources :members, only: [ :index, :create, :update, :destroy ] do
      member do
        delete :leave
      end
    end
    resources :invitations, only: [ :new, :create, :destroy ] do
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

  # Pay gem auto-mounts at /pay/webhooks/stripe via Pay.automount_routes

  # ==================================
  # Public Invoice Payment Routes
  # ==================================
  # These routes are public (no authentication required) for client invoice payments
  get "pay/:payment_token", to: "invoice_payments#show", as: :pay_invoice
  post "pay/:payment_token/checkout", to: "invoice_payments#checkout", as: :pay_invoice_checkout
  get "pay/:payment_token/success", to: "invoice_payments#success", as: :pay_invoice_success
  get "pay/:payment_token/cancel", to: "invoice_payments#cancel", as: :pay_invoice_cancel

  # ==================================
  # API V1 Routes
  # ==================================
  namespace :api do
    namespace :v1 do
      # Authentication
      scope :auth do
        post :token, to: "authentication#create", as: :auth_token
        delete :token, to: "authentication#destroy"
      end

      # User profile
      scope :users do
        get :me, to: "users#me", as: :users_me
        patch :me, to: "users#update"
      end

      # Accounts
      resources :accounts, only: [ :index, :show, :update ] do
        resources :memberships, only: [ :index, :create, :update, :destroy ]
      end

      # Notifications
      resources :notifications, only: [ :index, :show, :destroy ] do
        member do
          post :mark_as_read
        end
        collection do
          post :mark_all_as_read
          get :unread_count
        end
      end
    end
  end

  # ==================================
  # Owner Portal (Site Admins Only)
  # ==================================
  namespace :owner do
    root "dashboard#index"
    get "metrics", to: "dashboard#metrics"
    resources :accounts, only: [ :index, :show ]
    resources :reports, only: [ :index, :show ] do
      collection do
        get :mrr
        get :customers
        get :payments
      end
    end
  end

  # ==================================
  # Admin Dashboard
  # ==================================
  namespace :admin do
    root "dashboard#index"

    resources :users, only: [ :index, :show, :edit, :update, :destroy ] do
      member do
        post :impersonate
      end
      collection do
        delete :stop_impersonating
      end
    end

    resources :accounts, only: [ :index, :show, :edit, :update, :destroy ] do
      member do
        post :upgrade
        post :extend_trial
      end
    end
  end

  # ==================================
  # Notifications
  # ==================================
  resources :notifications, only: [ :index, :show, :destroy ] do
    collection do
      post :mark_all_as_read
    end
  end

  # ==================================
  # Messages / Conversations
  # ==================================
  resources :conversations, only: [ :index, :show, :new, :create, :destroy ] do
    resources :messages, only: [ :create, :destroy ]
  end

  # ==================================
  # Dashboard
  # ==================================
  get "dashboard", to: "dashboard#show", as: :dashboard

  # ==================================
  # Core Business Features
  # ==================================

  # Clients
  resources :clients do
    member do
      get :projects
      get :invoices
    end
  end

  # Projects with nested time/material entries
  resources :projects do
    resources :time_entries, only: [ :new, :create ]
    resources :material_entries, only: [ :new, :create ]
    resources :documents, only: [ :index, :new, :create ]
    member do
      patch :archive
      patch :complete
    end
  end

  # Invoices with nested line items
  resources :invoices do
    resources :line_items, controller: "invoice_line_items", only: [ :create, :update, :destroy ]
    member do
      patch :send_invoice
      patch :mark_paid
      patch :mark_cancelled
      get :preview
      get :download
    end
  end

  # Estimates/Quotes with nested line items
  resources :estimates do
    resources :line_items, controller: "estimate_line_items", only: [ :create, :update, :destroy ]
    member do
      post :send_estimate
      post :accept
      post :decline
      post :convert_to_invoice
      get :preview
      get :download
    end
  end

  # Documents (can be standalone or associated with project)
  resources :documents, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    member do
      get :download
    end
  end

  # Time Entries
  resources :time_entries do
    collection do
      get :report
    end
    member do
      patch :mark_invoiced
    end
  end

  # Material Entries
  resources :material_entries do
    collection do
      get :report
    end
    member do
      patch :mark_invoiced
    end
  end

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
