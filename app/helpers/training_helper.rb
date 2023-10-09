# frozen_string_literal: true

#= Helpers for training views
module TrainingHelper
  # Given a module slug, it returns the first library that has a
  # category including that module slug. It returns nil if no such
  # library is found.
  def find_library_from_module_slug(module_slug)
    TrainingLibrary.all.find_each do |library|
      library.categories.each do |category|
        next unless category.key?('modules')
        category['modules'].each do |mod|
          return library if mod['slug'] == module_slug
        end
      end
    end
  end

  # Given a slide slug, it returns the first module including it.
  # It returns nil if no such module is found.
  def find_module_from_slide_slug(slide_slug_to_find)
    TrainingModule.all.find_each do |mod|
      mod.slide_slugs.each do |slide_slug|
        return mod if slide_slug == slide_slug_to_find
      end
    end
  end
end
