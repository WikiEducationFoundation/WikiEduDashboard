# frozen_string_literal: true

# Diagnostic dump of what a launch actually carried, off unless
# LTI_LAUNCH_DEBUG is set. Logs the idtoken's top-level keys, its LTI version,
# the roles and platform claims (the two a legacy launch has to be checked
# for), the full `custom` object (Canvas ids and our resource marker, not PII),
# and the AGS service keys plus lineItemId value — never the serviceKey value.
#
# Its own class rather than a method on the launch concern: it is a debugging
# aid, not part of establishing a session, and the concern was over its length
# budget with it inside.
class LogLtiLaunchClaims
  def self.call(lti_session)
    idtoken = lti_session.idtoken
    ags = idtoken.dig('services', 'assignmentAndGrades') || {}
    Rails.logger.warn("[LTI launch] top=#{idtoken.keys.inspect} " \
                      "version=#{idtoken['ltiVersion'].inspect} " \
                      "roles=#{lti_session.user_roles.inspect} " \
                      "platform=#{idtoken['platform'].inspect} " \
                      "custom=#{idtoken['custom'].inspect} " \
                      "ags_keys=#{ags.keys.inspect} lineItemId=#{ags['lineItemId'].inspect}")
  end
end
