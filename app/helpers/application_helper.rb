# frozen_string_literal: true

#= Root-level helpers
module ApplicationHelper
  def logo_path
    logo_path = "/assets/images/#{Figaro.env.logo_file}"
    logo_path
  end

  def logo_tag
    logo_path = "/assets/images/#{Figaro.env.logo_file}"
    image_tag logo_path
  end

  def permissions
    if Features.wiki_ed? && current_user&.permissions == User::Permissions::NONE
      'true'
    else
      'false'
    end
  end

  def language_switcher_enabled
    Features.enable_language_switcher?.to_s
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
    survey_paths = %w[survey surveys rapidfire]
    return 'survey-page' if survey_paths.include?(base_path)
    return 'fixed-nav'
  end
end
