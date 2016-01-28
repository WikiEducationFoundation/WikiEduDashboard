class CustomStrategy < OmniAuth::Strategies::Mediawiki
  def parse_info(jwt_data)
    super
  rescue JWT::DecodeError
    fail!(:login_error)
    return { login_failed: true,
             jwt_data: jwt_data.body }
  end
end
