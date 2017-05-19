Rails.application.routes.draw do
  
  root to: 'home#index'

  resources :order_details, only: :destroy

  get 'order/vendors' => 'orders#load_terminal' ,:as => 'vendors'
  get 'orders/history' => 'orders#order_history' ,:as => 'orders'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  
  devise_for :users, :skip => [:registration],  controllers: { confirmations: 'confirmation' }
  as :user do
    get 'users/edit' => 'devise/registrations#edit', :as => 'edit_user_registration'
    patch 'users' => 'devise/registrations#update', :as => 'user_registration'
  end 

  resources :companies do
    
    member do
      get 'get_order_details'
    end

    resources :users do
      collection do
        get 'search'
        get 'download_invalid_csv'
        post 'add_multiple_employee_records'
        post 'import'
      end
    end

    resources :terminals do
      resources :menu_items do
        collection do
          post :import
        end
      end
    end
  
  end

  resources :terminals do
    resources :orders
  end
  
  # get 'companies/:company_id/terminals/:id/invalid_menu_download' => 'terminals#invalid_menu_download'
 
  get "menu_items/download_csv"
  get 'users/download_sample_file'

  get 'admin/dashboard/index', to: 'admin_dashboard#index'
  get 'admin/dashboard/order/detail', to: 'admin_dashboard#order_detail'
  get 'admin/dashboard/forward/orders', to: 'admin_dashboard#forward_orders'
  get 'admin/dashboard/place/orders', to: 'admin_dashboard#place_orders'
  get 'admin/dashboard/confirm_orders', to: 'admin_dashboard#confirm_orders'
  get 'admin/dashboard/payment', to: 'admin_dashboard#payment'
  get 'admin/dashboard/pay', to: 'admin_dashboard#pay'

  get 'admin/dashboard/terminals/extra/charges', to: 'admin_dashboard#input_terminal_extra_charges', 
    as: 'extra_charges_for_terminals'

  post 'admin_dashboard/save_terminal_extra_charges'

  delete 'admin_dashboard/:id(.:format)', :to => 'admin_dashboard#destroy', 
    :as => 'admin_dashboard_order_detail_remove'
  # delete 'edit/order_detail_id' => 'orders#order_detail_remove',:as => 'order_detail_remove'

  get 'reports/index'
  get 'reports/order/details', to: 'reports#order_details'
  get 'reports/download_daily_terminal_report'
  


  get 'reports/employee/:id/last/month/', to: 'reports#individual_employee_last_month_report', 
    as: 'individual_employee_last_month_report'
  
  get 'reports/employees/todays/orders', to: 'reports#employees_todays_orders', 
    as: 'employees_todays_orders'
  
  get 'reports/employees/monthly', to: 'reports#monthly_all_employees', 
    as: 'monthly_all_employees_reports'
  
  get "reports/download_pdf" => "reports#download_pdf"
  
  get 'reports/terminals/last/month/', to: 'reports#all_terminals_last_month_reports', 
    as: 'all_terminals_last_month_reports'
  
  get 'reports/terminals/daily', to: 'reports#all_terminals_daily_report', 
    as: 'all_terminals_daily_report'
  
  get 'reports/terminal/:id/last/month/', to: 'reports#individual_terminal_last_month_report', 
    as: 'individual_terminal_last_month_report'
  
  get 'reports/employees/daily/orders', to: 'reports#employees_daily_order_detail', 
    as: 'employees_daily_order_detail'
    
end
