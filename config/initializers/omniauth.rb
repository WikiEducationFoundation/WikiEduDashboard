require 'oauth'
require 'omniauth'
require 'omniauth-mediawiki'

# Rails.application.config.middleware.use Rack::Session::Cookie,
#                                         path: '/',
#                                         expire_after: 172_800,
#                                         secret: "sdjfh345hjkfsh48of48ht54h8f34fgdfgdrdgfgdr"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :mediawiki,
           Figaro.env.wikipedia_token,
           Figaro.env.wikipedia_secret,
           client_options: {
             site: 'https://en.wikipedia.org'
           }
end
