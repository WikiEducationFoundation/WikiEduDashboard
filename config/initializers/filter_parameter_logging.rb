# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
# `ltik` is the LTI launch bearer token: it authenticates an LMS launch to
# LTIAAS on its own, and it rides in query strings and form fields all through
# the launch flow, so it must not land in logs.
# `oauth_signature` is the HMAC on an inbound LTI 1.1 launch. The launch body
# is otherwise unremarkable, and `key` and `secret` above already cover
# `oauth_consumer_key` and `shared_secret` (Rails matches on substring), but a
# logged signature plus a replayed body is a launch someone else can send.
Rails.application.config.filter_parameters += %i[password token secret wiki_token wiki_secret
                                                 email api_key key ltik oauth_signature]
