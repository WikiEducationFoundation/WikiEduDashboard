# frozen_string_literal: true

require_dependency Rails.root.join('lib/utils/string_utils')

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
      { slide: slide.slug,
        title: highlight_kword_in(slide.title),
        excerpt: excerpt(slide.sanitized_content) }
    end
    add_libr_and_mod_slugs(slugs)

    slide_paths_with_excerpt(slugs)
  end

  private

  def add_libr_and_mod_slugs(slugs)
    slugs.each do |slug|
      trningmod = module_of_a_slide(slug[:slide])
      next if trningmod.nil?

      slug[:module], slug[:module_name] = [trningmod.slug, trningmod.slug]
      library_of_a_module(slug[:module]).then { |lib| slug[:library] = lib.slug unless lib.nil? }
    end

    reject_module_without_library(slugs)
  end

  def module_of_a_slide(slide_slug)
    TrainingModule.all.find { |mod| mod.slide_slugs.include?(slide_slug) }
  end

  def library_of_a_module(training_module)
    TrainingLibrary.all.find do |lib|
      lib.categories.pluck('modules').flatten.find { |o| o['slug'] == training_module }
    end
  end

  def reject_module_without_library(slugs)
    slugs.reject! { |obj| obj[:library].nil? }
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
      .select(:id, :slug, :title, "REGEXP_REPLACE(content, '#{ignore}', '') AS sanitized_content")
      .where("REGEXP_REPLACE(content, '#{ignore}', '') LIKE ? or title LIKE ?", srch, srch)
  end

  def ignore
    '<img.*>|<a href.*>|\\(http.*\\)'
  end

  def excerpt(text)
    StringUtils.excerpt(text, @search, EXCERPT_LENGTH)
  end

  def highlight_kword_in(title)
    StringUtils.highlight_kword(title, @search)
  end
end
