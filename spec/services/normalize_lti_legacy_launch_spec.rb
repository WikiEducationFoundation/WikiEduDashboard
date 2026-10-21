# frozen_string_literal: true

require 'rails_helper'

describe NormalizeLtiLegacyLaunch do
  # The parameters a real Canvas 1.1 launch carried, captured 2026-09-15.
  let(:params) do
    { 'lti_message_type' => 'basic-lti-launch-request', 'lti_version' => 'LTI-1p0',
      'user_id' => '86157096483e6b3a50bfedc6bac902c0b20a824f',
      'roles' => 'Instructor,urn:lti:sysrole:ims/lis/SysAdmin',
      'context_id' => '2300c772b3df735be28419065e87fd6a1a24e102',
      'context_label' => 'ENVS-350', 'context_title' => 'Environmental Policy',
      'resource_link_id' => '2300c772b3df735be28419065e87fd6a1a24e102',
      'resource_link_title' => 'wikiedu.org',
      'launch_presentation_document_target' => 'iframe',
      'launch_presentation_return_url' => 'https://canvas.example.edu/courses/1/external_content',
      'custom_canvas_enrollment_state' => 'active',
      'tool_consumer_instance_guid' => 'Uo7bOjy7:canvas-lms',
      'tool_consumer_instance_name' => 'Example University',
      'tool_consumer_info_product_family_code' => 'canvas',
      'tool_consumer_info_version' => 'cloud' }
  end

  subject(:idtoken) { described_class.new(params, course_id: 42).idtoken }

  # The shape has to match what LTIAAS produced for the same launch, because
  # everything downstream of LtiSession reads it without knowing which
  # terminator built it.
  it 'reports the version LTIAAS uses for a legacy launch' do
    expect(idtoken['ltiVersion']).to eq('1.2.0')
  end

  it 'carries the opaque user id and the roles exactly as Canvas sent them' do
    expect(idtoken.dig('user', 'id')).to eq('86157096483e6b3a50bfedc6bac902c0b20a824f')
    expect(idtoken.dig('user', 'roles'))
      .to eq(['Instructor', 'urn:lti:sysrole:ims/lis/SysAdmin'])
  end

  # No platform.id exists under 1.1; the instance guid is the identity, and
  # LtiSession falls back to it.
  it 'puts the Canvas instance guid where LtiSession looks for the platform' do
    expect(idtoken.dig('platform', 'guid')).to eq('Uo7bOjy7:canvas-lms')
    expect(idtoken.dig('platform', 'id')).to be_nil
    expect(idtoken.dig('platform', 'productFamilyCode')).to eq('canvas')
  end

  it 'carries the return URL, which is the only clue to the Canvas base URL' do
    expect(idtoken.dig('launch', 'presentation', 'returnUrl'))
      .to eq('https://canvas.example.edu/courses/1/external_content')
  end

  it 'carries the context and resource link' do
    expect(idtoken.dig('launch', 'context', 'title')).to eq('Environmental Policy')
    expect(idtoken.dig('launch', 'resourceLink', 'id'))
      .to eq('2300c772b3df735be28419065e87fd6a1a24e102')
  end

  it 'strips the prefix from custom parameters and puts them where they are read' do
    expect(idtoken.dig('custom', 'canvas_enrollment_state')).to eq('active')
  end

  # Companion mode: no roster service, no line items, no scores.
  it 'declares every LTI service unavailable' do
    expect(idtoken['services'].values.map { |s| s['available'] }).to all(be false)
  end

  it 'carries the issuing key\'s course claim under our own key' do
    expect(idtoken.dig('dashboard', 'courseId')).to eq(42)
  end

  # The real proof that the shape is right: a session built from it answers the
  # same questions the app asks of an LTIAAS-built one.
  describe 'read back through LtiSession' do
    subject(:session) { LtiSession.new(idtoken:) }

    it 'is a legacy Canvas launch by an instructor' do
      expect(session).to be_legacy
      expect(session.lti_version).to eq('1.2.0')
      expect(session).to be_supported_lms
      expect(session).to be_instructor
    end

    it 'resolves the identity, context and platform URL the app needs' do
      expect(session.lms_id).to eq('Uo7bOjy7:canvas-lms')
      expect(session.lms_context_id).to eq('2300c772b3df735be28419065e87fd6a1a24e102')
      expect(session.context_title).to eq('Environmental Policy')
      expect(session.platform_url).to eq('https://canvas.example.edu')
      expect(session.claimed_course_id).to eq(42)
    end

    it 'has no services behind it' do
      expect(session.nrps_url).to be_nil
      expect(session.ags_lineitems_url).to be_nil
      expect(session.service_key).to be_nil
    end
  end
end
