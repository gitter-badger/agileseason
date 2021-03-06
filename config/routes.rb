require 'sidekiq/web'

Rails.application.routes.draw do
  resources :repos, only: [:index]
  resource :docs, only: [] do
    member do
      get :main
      get :board_features
      get :cumulative
      get :control
    end
  end

  resource :preferences, only: [:update]

  resources :boards,
            except: [:edit],
            param: :github_full_name,
            constraints: { github_full_name: /[0-9A-Za-z\-_\.]+(\/|%2F)[0-9A-Za-z\-_\.]+/ } do

    resources :columns do
      member do
        get :move_left
        get :move_right
        patch :update_attribute
        get :settings
      end
    end

    resource :issues, only: [:new, :create] do
      get :search, :collection
      get ':number', to: 'issues#show', as: :show
      get ':number/move_to/:column_id(/:force)', to: 'issues#move_to', as: :move_to_column
      get ':number/close', to: 'issues#close', as: :close
      get ':number/reopen', to: 'issues#reopen', as: :reopen
      get ':number/archive', to: 'issues#archive', as: :archive
      get ':number/unarchive', to: 'issues#unarchive', as: :unarchive
      get ':number/assignee/:login', to: 'issues#assignee', as: :assignee
      get ':number/fetch_miniature', to: 'issues#fetch_miniature', as: :fetch_miniature
      post ':number/due_date', to: 'issues#due_date', as: :due_date
      post ':number/toggle_ready', to: 'issues#toggle_ready', as: :toggle_ready
      patch ':number/update', to: 'issues#update', as: :update
      patch ':number/update_labels', to: 'issues#update_labels', as: :update_labels

      get ':number/comments', to: 'comments#index', as: :comments
      post ':number/comment', to: 'comments#create', as: :add_comment
      post ':number/update_comment/:id', to: 'comments#update', as: :update_comment
      delete ':number/delete_comment/:id', to: 'comments#delete', as: :delete_comment
    end

    resource :settings, only: [:show, :update] do
      member do
        patch :rename
        get :apply_hook
        delete :remove_hook
      end
    end

    namespace :graphs do
      resources :lines, only: [:index]
      resources :cumulative, only: [:index]
      resources :control, only: [:index]
      resources :frequency, only: [:index]
    end

    resource :subscriptions, only: [:new] do
      get :early_access
    end

    resource :roadmap, only: [:show] do
      post :build
    end

    resources :activities, only: [:index]
    resources :issue_stats, only: :update
    resource :exports, only: [:show]

    post 'preview', to: 'markdown#preview', as: :preview
  end

  mount Sidekiq::Web => '/sidekiq', constraints: SidekiqConstraint.new

  get '/auth/github/callback', to: 'sessions#create'
  get '/sign_out', to: 'sessions#destroy'

  get '/awstest', to: 'awstest#index'
  get '/demo', to: 'landing#demo', as: :demo
  get '/mixpanel_events/client_event', to: 'mixpanel_events#client_event'
  post '/webhooks/github'

  root 'landing#index'
end
