# frozen_string_literal: true

# LTI 1.1 tool configuration for Canvas's "By URL" / "Paste XML" install. See
# LtiConfigController. Field reference: Canvas's LTI 1.1 XML config docs
# (https://developerdocs.instructure.com/services/canvas/external-tools/lti/file.tools_xml).
xml.instruct!
xml.cartridge_basiclti_link(
  'xmlns' => 'http://www.imsglobal.org/xsd/imslticc_v1p0',
  'xmlns:blti' => 'http://www.imsglobal.org/xsd/imsbasiclti_v1p0',
  'xmlns:lticm' => 'http://www.imsglobal.org/xsd/imslticm_v1p0',
  'xmlns:lticp' => 'http://www.imsglobal.org/xsd/imslticp_v1p0',
  'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
  'xsi:schemaLocation' => 'http://www.imsglobal.org/xsd/imslticc_v1p0 ' \
                          'http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd ' \
                          'http://www.imsglobal.org/xsd/imsbasiclti_v1p0 ' \
                          'http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd ' \
                          'http://www.imsglobal.org/xsd/imslticm_v1p0 ' \
                          'http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd ' \
                          'http://www.imsglobal.org/xsd/imslticp_v1p0 ' \
                          'http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd'
) do
  # Same tool name the 1.3 registration shows in Canvas.
  xml.blti :title, 'wikiedu.org'
  xml.blti :launch_url, @launch_url
  xml.blti :secure_launch_url, @launch_url
  xml.blti :vendor do
    xml.lticp :code, 'wikiedu'
    xml.lticp :name, 'Wiki Education'
    xml.lticp :url, 'https://wikiedu.org'
  end
  xml.blti :extensions, platform: 'canvas.instructure.com' do
    xml.lticm :property, 'wikiedu_dashboard_lti11', name: 'tool_id'
    # Anonymous: Canvas sends an opaque user id and the course role, no name or
    # email — the same posture as the 1.3 registration's privacyLevel.
    xml.lticm :property, 'anonymous', name: 'privacy_level'
    # No `domain` property on purpose. A navigation-only tool doesn't need
    # domain matching (it only serves module-item links), and Canvas's tool
    # uniqueness check compares domains, so leaving it out keeps a 1.1 install
    # from ever colliding with a 1.3 install on the same LTIAAS domain.
    xml.lticm :options, name: 'course_navigation' do
      xml.lticm :property, 'true', name: 'enabled'
      xml.lticm :property, 'enabled', name: 'default'
      xml.lticm :property, 'members', name: 'visibility'
      xml.lticm :property, 'wikiedu.org', name: 'text'
    end
  end
  xml.cartridge_bundle identifierref: 'BLTI001_Bundle'
  xml.cartridge_icon identifierref: 'BLTI001_Icon'
end
