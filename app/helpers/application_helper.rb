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
    file_without_extension = File.basename(filename).split('.')[0]
    extname = File.extname(filename)
    "#{path}#{file_without_extension}#{extname}"
  end
end
