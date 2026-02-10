Rails.application.routes.draw do
  # Health check
  get "up", to: proc { [200, {}, ["OK"]] }

  # API Documentation
  # Serve OpenAPI spec
  get '/openapi.yaml', to: proc { 
    [200, 
     { 'Content-Type' => 'text/yaml' }, 
     [File.read(Rails.root.join('doc', 'openapi.yaml'))]
    ] 
  }
  
  # Swagger UI is served from public/api-docs.html (static file)

  namespace :api do
    namespace :v1 do
      # ── Authentication ──────────────────────────────────────────
      post   "auth/register",    to: "authentication#register"
      post   "auth/login",       to: "authentication#login"
      post   "auth/refresh",     to: "authentication#refresh"
      post   "auth/logout",      to: "authentication#logout"
      post   "auth/logout_all",  to: "authentication#logout_all"
      get    "auth/profile",     to: "authentication#profile"
      put    "auth/profile",     to: "authentication#update_profile"

      # ── Photos ──────────────────────────────────────────────────
      resources :photos, only: [:index, :show, :create, :update, :destroy] do
        member do
          post   :favorite
          delete :unfavorite
        end
      end

      # ── Photographers ───────────────────────────────────────────
      resources :photographers, only: [:index, :show]

      # ── Albums ──────────────────────────────────────────────────
      resources :albums do
        member do
          post   "photos/:photo_id", to: "albums#add_photo",    as: :add_photo
          delete "photos/:photo_id", to: "albums#remove_photo", as: :remove_photo
        end
      end

      # ── Favorites ───────────────────────────────────────────────
      get "favorites", to: "favorites#index"
    end
  end
end
