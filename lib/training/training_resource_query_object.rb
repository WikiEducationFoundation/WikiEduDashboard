# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/utils/string_utils"

class TrainingResourceQueryObject
  EXCERPT_LENGTH = 60

  def initialize(current_user, search = nil)
    @current_user = current_user
    @search = search
  end

  def all_libraries
    libraries = TrainingLibrary.all.sort_by do |library|
      library.slug == focused_library_slug ? 0 : 1
    end

    [focused_library_slug, libraries]
  end

  def selected_slides_and_excerpt
    slugs = search_content_in_slides.map do |slide|
      { slide: slide.slug, title: slide.title, excerpt: excerpt(slide.content) }
    end
    add_libr_and_mod_slugs(slugs)

    slide_paths_with_excerpt(slugs)
  end

  private

  def add_libr_and_mod_slugs(slugs)
    slugs.each do |slug|
      slug[:module], slug[:module_name] =
        module_of_a_slide(slug[:slide]).then { |tm| [tm.slug, tm.name] }
      slug[:library] = library_of_a_module(slug[:module]).slug
    end
  end

  def module_of_a_slide(slide_slug)
    TrainingModule.all.find { |mod| mod.slide_slugs.include?(slide_slug) }
  end

  def library_of_a_module(training_module)
    TrainingLibrary.all.find do |lib|
      lib.categories.pluck('modules').flatten.find { |o| o['slug'] == training_module }
    end
  end

  def slide_paths_with_excerpt(slugs)
    slugs.map do |slg|
      { path: slg.values_at(:library, :module, :slide).join('/'),
        module: slg.values_at(:library, :module).join('/'),
        module_name: slg[:module_name],
        excerpt: slg[:excerpt],
        title: slg[:title] }
    end
  end

  def focused_library_slug
    @current_user&.courses&.last&.training_library_slug
  end

  def search_content_in_slides
    srch = "%#{@search}%"
    TrainingSlide
      .where('content LIKE ? or title LIKE ?', srch, srch)
  end

  def excerpt(text)
    StringUtils.excerpt(text, @search, EXCERPT_LENGTH)
  end
end
