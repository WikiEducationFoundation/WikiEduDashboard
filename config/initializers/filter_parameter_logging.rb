# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
# `ltik` is the LTI launch bearer token: it authenticates an LMS launch to
# LTIAAS on its own, and it rides in query strings and form fields all through
# the launch flow, so it must not land in logs.
Rails.application.config.filter_parameters += %i[password token secret wiki_token wiki_secret
                                                 email api_key key ltik]
