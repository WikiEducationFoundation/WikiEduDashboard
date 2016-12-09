# frozen_string_literal: true

#= Root-level helpers
module ApplicationHelper
  def logo_tag
    logo_path = "/assets/images/#{Figaro.env.logo_file}"
    image_tag logo_path
  end

  def logo_favicon_tag
    favicon_path = if Rails.env == 'development'
                     "/assets/images/#{Figaro.env.favicon_dev_file}"
                   else
                     "/assets/images/#{Figaro.env.favicon_file}"
                   end

    favicon_link_tag favicon_path
  end

  def dashboard_stylesheet_tag(filename)
    if Features.hot_loading?
      stylesheet_link_tag "/assets/stylesheets/#{rtl? ? 'rtl-' : nil}#{filename}.css"
    else
      file_prefix = rtl? ? 'rtl-' : nil
      stylesheet_link_tag fingerprinted('/assets/stylesheets/', "#{filename}.css", file_prefix),
                          media: 'all'
    end
  end

  def hot_javascript_tag(filename)
    if Features.hot_loading?
      javascript_include_tag "http://localhost:8080/#{filename}.js"
    else
      javascript_include_tag fingerprinted('/assets/javascripts/', "#{filename}.js")
    end
  end

  def fingerprinted(path, filename, file_prefix = nil)
    manifest_path = "#{Rails.root}/public/#{path}/rev-manifest.json"
    manifest = JSON.parse(File.read(File.expand_path(manifest_path, __FILE__)))
    "#{path}#{file_prefix}#{manifest[filename]}"
  end

  def class_for_path(req, path)
    return 'active' if req.path == '/' && path == '/'
    current_path_segments = req.path.split('/').reject(&:blank?)
    active_path = path.split('/').reject(&:blank?).last
    current_path_segments.include?(active_path) ? 'active' : nil
  end

  def body_class(request)
    base_path = request.path.split('/')[1]
    return 'course-page' if base_path == 'courses'
    return 'campaign-path' if base_path == 'campaigns'
    survey_paths = %w(survey surveys rapidfire)
    return 'survey-page' if survey_paths.include?(base_path)
    return 'fixed-nav'
  end

  ############################
  # Rapidfire Survey patches #
  ############################

  # When called from a /rapidfire/ view, shared templates will use
  # the rapidfire engine's routes to respond to _path and _url helpers, rather
  # than the main app's routes.
  # We define them here explicitly and send them to the main app.
  SHARED_ROUTES = [:explore_path, :destroy_user_session_path, :training_path,
                   :surveys_path, :results_path, :survey_assignments_path,
                   :user_mediawiki_omniauth_authorize_path].freeze
  SHARED_ROUTES.each do |method|
    define_method method do
      main_app.send(method)
    end
  end
end
