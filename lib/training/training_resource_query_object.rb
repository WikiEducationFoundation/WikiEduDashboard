# frozen_string_literal: true

class TrainingResourceQueryObject
  def self.find_libraries(...)
    new(...).find_libraries
  end

  def initialize(search, current_user)
    @search = search
    @current_user = current_user
  end

  def find_libraries
    if @search
      search_for_libraries
    else
      all_libraries
    end
  end

  private

  def all_libraries
    libraries = TrainingLibrary.all.sort_by do |library|
      library.slug == focused_library_slug ? 0 : 1
    end

    [focused_library_slug, libraries]
  end

  def search_for_libraries
    library_ids, category_slugs = find_libraries_from_modules
    libraries = TrainingLibrary.where(id: library_ids)
    libraries.each do |lib|
      lib.categories = ['modules' => []]
    end
    category_slugs.each do |lib_id, modules|
      libraries.find { |l| l.id == lib_id }.categories.first['modules'] = modules
    end

    [focused_library_slug, libraries]
  end

  def focused_library_slug
    @current_user&.courses&.last&.training_library_slug
  end

  def search_content_in_slides
    srch = "%#{@search}%"
    TrainingSlide
      .where('content LIKE ? or title LIKE ?', srch, srch)
      .map(&:slug)
  end

  def find_modules_slugs_from_content
    module_slugs = []
    search_content_in_slides.each do |slug|
      tr_module = TrainingModule.all.find { |mod| mod.slide_slugs.include?(slug) }
      module_slugs << tr_module.slug unless tr_module.nil?
    end
    TrainingModule.where(slug: module_slugs).pluck(:slug)
  end

  def find_libraries_from_modules
    ids_libraries = []
    cat_slugs = {}
    cat_slugs.default = []
    module_slugs = find_modules_slugs_from_content
    module_slugs.each do |mdl|
      TrainingLibrary.all.each do |lib|
        md = lib.categories.pluck('modules').flatten.select { |o| o['slug'] == mdl }
        unless md.empty?
          ids_libraries << lib.id
          cat_slugs[lib.id] += md
        end
      end
    end

    [ids_libraries, cat_slugs]
  end
end
