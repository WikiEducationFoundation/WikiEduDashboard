# frozen_string_literal: true
require 'rails_helper'
require "#{Rails.root}/lib/errors/rescue_development_errors"

describe Errors::RescueDevelopmentErrors, type: :controller do
  describe 'when ActionView::Template::Error is raised' do
    controller(ApplicationController) do
      include Errors::RescueDevelopmentErrors

      def index
        error_message = 'No such file or directory @ rb_sysopen - '\
                        '/home/me/WikiEduDashboard/public/assets/stylesheets/rev-manifest.json'
        # First we raise a standard error to set the original error, which
        # is needed by ActionView::Template::Error
        raise StandardError, error_message
      rescue
        # Then we raise the actual template error, which takes a template path
        # as its argument and pulls the original error object from $!
        raise ActionView::Template::Error, 'app/views/layouts/application.html.haml'
      end
    end

    it 'renders an explanation with helpful advice' do
      get :index
      expect(response.body).to match(/gulp/)
    end
  end

  describe 'when CoursesPresenter::NoCohortError is raised' do
    controller(ApplicationController) do
      include Errors::RescueDevelopmentErrors

      def index
        raise CoursesPresenter::NoCohortError
      end
    end

    it 'renders an explanation with helpful advice' do
      get :index
      expect(response.body).to match(/default cohort/)
    end
  end
end
