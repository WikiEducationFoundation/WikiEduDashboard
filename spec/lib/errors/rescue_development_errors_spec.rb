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
        raise ActionView::Template::Error.new(error_message, StandardError.new(error_message))
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
