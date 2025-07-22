# frozen_string_literal: true

# == Schema Information
#
# Table name: user_profiles
#
#  id                 :integer          not null, primary key
#  bio                :text(65535)
#  user_id            :integer
#  image_file_name    :string(255)
#  image_content_type :string(255)
#  image_file_size    :bigint
#  image_updated_at   :datetime
#  location           :string(255)
#  institution        :string(255)
#  email_preferences  :text(65535)
#  image_file_link    :string(255)
#
require 'rails_helper'

describe UserProfile do
  let(:user_profile) { create(:user_profile) }

  describe '#email_opt_out' do
    let(:subject) { user_profile.email_opt_out('InvalidType') }

    it 'raises an error if the type is invalid' do
      expect { subject }.to raise_error(UserProfile::InvalidEmailPreferencesType)
    end
  end
end
