# frozen_string_literal: true

require 'rails_helper'

describe LtiLaunchHelper, type: :helper do
  describe '#lti_iframe_content' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('dashboard_url').and_return('dashboard.wikiedu.org')
    end

    it 'returns html_safe output' do
      expect(helper.lti_iframe_content('<p>hello</p>')).to be_html_safe
    end

    it 'sanitizes markup before rewriting links' do
      output = helper.lti_iframe_content('<p>hi<script>alert(1)</script></p>')
      expect(output).not_to include('<script>')
    end

    it 'rewrites links to open outside the iframe' do
      output = helper.lti_iframe_content('<a href="/training/students">trainings</a>')
      expect(output).to include('href="https://dashboard.wikiedu.org/training/students"')
      expect(output).to include('target="_blank"')
      expect(output).to include('rel="noopener"')
    end

    it 'strips target values the author supplied, then reapplies via the rewrite' do
      output = helper.lti_iframe_content('<a href="https://example.com" target="evil">x</a>')
      expect(output.scan('target=').count).to eq(1)
      expect(output).to include('target="_blank"')
    end
  end
end
