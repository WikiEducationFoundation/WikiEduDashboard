require 'rails_helper'

describe ApplicationHelper, type: :helper do
  it 'should return a different favicon in the dev environment' do
    allow(Rails).to receive(:env).and_return('development')
    expected_path = "/assets/images/#{Figaro.env.favicon_dev_file}"
    expected_tag = favicon_link_tag expected_path
    expect(logo_favicon_tag).to eq(expected_tag)
  end
end
