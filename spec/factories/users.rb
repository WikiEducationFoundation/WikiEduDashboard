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
#

FactoryGirl.define do
  factory :test_user, class: User do
    username 'Pizza'
    onboarded true
  end

  factory :user do
    id '4543197'
    username 'Ragesock'
    onboarded true
  end

  factory :trained, class: User do
    id '319203'
    username 'Ragesoss'
    onboarded true
  end

  factory :admin, class: User do
    id '1'
    username 'Ragesauce'
    permissions '1'
    onboarded true
  end
end
