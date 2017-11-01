# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  username            :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  trained             :boolean          default(FALSE)
#  global_id           :integer
#  remember_created_at :datetime
#  remember_token      :string(255)
#  wiki_token          :string(255)
#  wiki_secret         :string(255)
#  permissions         :integer          default(0)
#  real_name           :string(255)
#  email               :string(255)
#  onboarded           :boolean          default(FALSE)
#  greeted             :boolean          default(FALSE)
#  greeter             :boolean          default(FALSE)
#  locale              :string(255)
#  chat_password       :string(255)
#  chat_id             :string(255)
#  registered_at       :datetime
#

FactoryBot.define do
  factory :test_user, class: User do
    username 'Pizza'
    onboarded true
  end

  factory :user do
    username 'Ragesock' # en.wiki local id 4543197
    onboarded true
  end

  factory :trained, class: User do
    username 'Ragesoss' # en.wiki local id 319203
    onboarded true
  end

  factory :admin, class: User do
    username 'Ragesauce'
    permissions 1
    onboarded true
  end
end
