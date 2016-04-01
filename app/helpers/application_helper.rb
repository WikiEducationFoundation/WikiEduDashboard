#= Root-level helpers
module ApplicationHelper

  def logo_tag
    logo_path = "/assets/images/#{Figaro.env.logo_file}"
    image_tag logo_path
  end

  def logo_favicon_tag
    if Rails.env == 'development' || Rails.env == 'developmentcp'
      favicon_path = "/assets/images/#{Figaro.env.favicon_dev_file}"
    else
      favicon_path = "/assets/images/#{Figaro.env.favicon_file}"
    end

    favicon_link_tag favicon_path
  end

  def dashboard_stylesheet_tag(filename)
    if Features.hot_loading?
      stylesheet_link_tag "/assets/stylesheets/#{filename}.css"
    else
      stylesheet_link_tag fingerprinted("/assets/stylesheets/#{rtl? ? 'rtl/' : nil}", "#{filename}.css"), media: 'all'
    end
  end

  def hot_javascript_tag(filename)
    if Features.hot_loading?
      javascript_include_tag "http://localhost:8080/#{filename}.js"
    else
      javascript_include_tag fingerprinted('/assets/javascripts/', "#{filename}.js")
    end
  end

  def fingerprinted(path, filename)
    manifest_path = "#{Rails.root}/public/#{path}/rev-manifest.json"
    manifest = JSON.parse(File.read(File.expand_path(manifest_path, __FILE__)))
    "#{path}#{manifest[filename]}"
  end

  def class_for_path(req, path)
    return 'active' if req.path == '/' && path == '/'
    req.path.split('/').reject(&:blank?).first == path.gsub('/', '') ? 'active' : nil
  end

  def body_class(request)
    case request.path.split('/')[1]
    when 'courses'
      return 'course-page'
    when 'surveys'
      return 'survey-page'
    when 'rapidfire'
      return 'survey-page'
    else
      return 'fixed-nav'
    end
  end

  def method_missing method, *args, &block
    # puts "LOOKING FOR ROUTES #{method}"
    if method.to_s.end_with?('_path') or method.to_s.end_with?('_url')
      if main_app.respond_to?(method)
        main_app.send(method, *args)
      else
        super
      end
    else
      super
    end
  end

  def respond_to?(method)
    if method.to_s.end_with?('_path') or method.to_s.end_with?('_url')
      if main_app.respond_to?(method)
        true
      else
        super
      end
    else
      super
    end
  end
end
