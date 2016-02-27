require 'active_model_serializers'

module Rapidfire
  class Engine < ::Rails::Engine
    isolate_namespace Rapidfire
  end
end
