class ApplicationController < ActionController::Base
  protect_from_forgery

  def current_user
    nil
  end

  def can_administer?
    true
  end
end
