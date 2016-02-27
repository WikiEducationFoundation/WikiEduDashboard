# inspired by devise and forem
require 'rails/generators'

module Rapidfire
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path('../../../../app/views/rapidfire', __FILE__)
      desc 'Copies default Rapidfire views to your application.'

      def copy_views
        view_directory :answer_groups
        view_directory :answers
        view_directory :question_groups
        view_directory :questions
      end

      protected
      def view_directory(name)
        directory name.to_s, "app/views/rapidfire/#{name}"
      end
    end
  end
end
