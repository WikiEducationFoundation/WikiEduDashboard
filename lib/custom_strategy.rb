class LoginError < StandardError; end

class CustomStrategy < OmniAuth::Strategies::Mediawiki
  def parse_info(jwt_data)
    begin
      super
    rescue JWT::DecodeError
      request.env['JWT_ERROR'] = true
      request.env['JWT_DATA'] = jwt_data
    end
  end
end
