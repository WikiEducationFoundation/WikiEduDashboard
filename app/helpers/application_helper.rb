# frozen_string_literal: true

#= Root-level helpers
module ApplicationHelper
  def logo_path
    "/assets/images/#{ENV['logo_file']}"
  end

  def language_switcher_enabled
    # If the language switcher is not enabled site-wide, show it anyway for users
    # with a non-English browser-based locale and for users with an explicit locale set.
    (Features.enable_language_switcher? || I18n.locale != :en || current_user&.locale&.present?)
      .to_s
  end

  def logo_favicon_tag
    favicon_link_tag "/assets/images/#{ENV['favicon_file']}"
  end

  def dashboard_stylesheet_tag(filename)
    filename = "#{rtl? ? 'rtl-' : nil}#{filename}.css"
    filename = css_fingerprinted(filename) unless Features.hot_loading?
    stylesheet_link_tag "/assets/stylesheets/#{filename}", media: 'all'
  end

  def hot_javascript_tag(filename)
    javascript_include_tag hot_javascript_path(filename)
  end

  def hot_javascript_path(filename)
    return "/assets/javascripts/#{filename}.js" if Features.hot_loading?
    fingerprinted('/assets/javascripts/', filename)
  end

  def fingerprinted(path, filename, file_prefix = nil)
    manifest_path = "#{Rails.root}/public/#{path}/manifest.json"
    manifest = Oj.load(File.read(File.expand_path(manifest_path, __FILE__)))
    "#{file_prefix}#{manifest["#{filename}.js"]}"
  end

  def css_fingerprinted(filename)
    manifest_path = "#{Rails.root}/public/assets/javascripts/manifest.json"
    manifest = Oj.load(File.read(File.expand_path(manifest_path, __FILE__)))
    manifest[filename].split('/').last
  end

  def en_if_invalid(locale)
    # if the locale is not valid, use the default locale
    return 'en' unless File.exist?("#{Rails.root}/public/assets/javascripts/i18n/#{locale}.js")
    locale
  end

  def i18n_javascript_tag(locale)
    locale = en_if_invalid(locale)
    md5 = Digest::MD5.file("#{Rails.root}/public/assets/javascripts/i18n/#{locale}.js").hexdigest
    javascript_include_tag "/assets/javascripts/i18n/#{locale}.js?v=#{md5}"
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
