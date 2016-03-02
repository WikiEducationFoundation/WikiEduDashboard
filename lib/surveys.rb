require 'active_support'
require 'rapidfire'

Rails.application.config.to_prepare do
  Rapidfire::ApplicationController.class_eval do
    layout 'surveys'
  end
end