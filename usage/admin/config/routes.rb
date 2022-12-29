Rails.application.routes.draw do
  get 'plugins/index'
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  root to: "admin/computing_units#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
