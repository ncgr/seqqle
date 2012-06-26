ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'seqqles'

  map.resources :seqqles,
    :constraints => {:id => /[A-Z][a-z][0-9][-]+/},
    :only => [:index, :new, :show, :create],
    :as => 'seqqle'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
