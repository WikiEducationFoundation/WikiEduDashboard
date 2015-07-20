#= Root-level helpers
module ApplicationHelper
  def logo_tag
    logo_path = "/images/#{Figaro.env.logo_file}"
    image_tag logo_path
  end

  def logo_favicon_tag
    if Rails.env == 'development' || Rails.env == 'developmentcp'
      favicon_path = "/images/#{Figaro.env.favicon_dev_file}"
    else
      favicon_path = "/images/#{Figaro.env.favicon_file}"
    end

    favicon_link_tag favicon_path
  end
end
