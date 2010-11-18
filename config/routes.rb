ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'users', :action => 'biz'

  map.twitter_login '/twitter_login', :controller => 'users', :action => 'create'
#  map.login '/login', :controller => 'users', :action => 'login'
  #map.biz '/biz', :controller => 'users', :action => 'biz'
  map.logout '/logout', :controller => 'users', :action => 'destroy'
#  map.resources :users, :collection => {:link_user_accounts => :get}

  map.connect '/callback', :controller => 'users', :action => 'callback'

  map.profile '/profile', :controller => 'users', :action => 'profile'
  map.preferences '/preferences', :controller => 'users', :action => 'preferences'
  map.product_catalog '/product_catalog', :controller => 'products', :action => 'product_catalog'

  map.wardrobe '/wardrobe', :controller => 'products', :action => 'wardrobe'
  map.combinations '/combinations/:id', :controller => 'products', :action => 'combinations'

  map.payments '/payments/:id', :controller => 'products', :action => 'payments'

  map.discover '/discover/:id', :controller => 'products', :action => 'discover'
  map.schedule '/schedule/:id', :controller => 'products', :action => 'schedule'

  map.analytics '/analytics', :controller => 'home', :action => 'analytics'
  map.notifications '/notifications', :controller => 'home', :action => 'notifications'
  map.my_wardrobes '/my_wardrobes', :controller => 'home', :action => 'my_wardrobes'

  map.wardrobes '/wardrobes', :controller => 'home', :action => 'wardrobes'
  map.say_your_price '/say_your_price', :controller => 'home', :action => 'say_your_price'
  map.winners '/winners', :controller => 'home', :action => 'winners'

  map.faqs '/faqs', :controller => 'home', :action => 'faqs'

  map.send_to '/:id/sendto', :controller => 'products', :action => 'send_to'
  map.capsule '/:id', :controller => 'products', :action => 'capsule'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
