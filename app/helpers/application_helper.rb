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
    else
      return 'fixed-nav'
    end
  end

  def survey_page(request)
    root_path = request.path.split('/')[1] 
    root_path == 'surveys' || root_path == 'survey'
  end

  def can_administer?
    current_user && current_user.admin?
  end

  def question_type(answer)
    answer.question.type.to_s.split("::").last.downcase
  end

  def is_required_question?(answer)
    answer.question.validation_rules[:presence]
  end
  
end
