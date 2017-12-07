# frozen_string_literal: true
# == Schema Information
#
# Table name: courses
#
#  id                    :integer          not null, primary key
#  title                 :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  start                 :datetime
#  end                   :datetime
#  school                :string(255)
#  term                  :string(255)
#  character_sum         :integer          default(0)
#  view_sum              :integer          default(0)
#  user_count            :integer          default(0)
#  article_count         :integer          default(0)
#  revision_count        :integer          default(0)
#  slug                  :string(255)
#  subject               :string(255)
#  expected_students     :integer
#  description           :text(65535)
#  submitted             :boolean          default(FALSE)
#  passcode              :string(255)
#  timeline_start        :datetime
#  timeline_end          :datetime
#  day_exceptions        :string(2000)     default("")
#  weekdays              :string(255)      default("0000000")
#  new_article_count     :integer          default(0)
#  no_day_exceptions     :boolean          default(FALSE)
#  trained_count         :integer          default(0)
#  cloned_status         :integer
#  type                  :string(255)      default("ClassroomProgramCourse")
#  upload_count          :integer          default(0)
#  uploads_in_use_count  :integer          default(0)
#  upload_usages_count   :integer          default(0)
#  syllabus_file_name    :string(255)
#  syllabus_content_type :string(255)
#  syllabus_file_size    :integer
#  syllabus_updated_at   :datetime
#  home_wiki_id          :integer
#  recent_revision_count :integer          default(0)
#  needs_update          :boolean          default(FALSE)
#  chatroom_id           :string(255)
#  flags                 :text(65535)
#  level                 :string(255)
#  private               :boolean          default(FALSE)
#

FactoryBot.define do
  factory :course, class: 'ClassroomProgramCourse' do
    start Date.new(2015, 1, 1)
    self.end Date.new(2015, 6, 1)
    title 'Underwater basket-weaving'
    school 'WINTR'
    term 'spring 2015'
    slug 'WINTR/Underwater_basket-weaving_(spring_2015)'
    passcode 'pizza'
    home_wiki_id 1
  end

  factory :basic_course, class: 'BasicCourse' do
    start Date.new(2015, 1, 1)
    self.end Date.new(2015, 6, 1)
    title 'Black life matters'
    school 'none'
    term 'none'
    slug 'Black_life_matters'
    type 'BasicCourse'
    passcode 'pizzå'
    home_wiki_id 1
  end

  factory :visiting_scholarship, class: 'VisitingScholarship' do
    start Date.new(2015, 1, 1)
    self.end Date.new(2015, 6, 1)
    title 'Basket-weaving scholarship'
    school 'UNR'
    term 'spring 2015'
    slug 'UNR/Basket-weaving_scholarship_(spring_2015)'
    passcode 'pizza'
    type 'VisitingScholarship'
    home_wiki_id 1
  end

  factory :editathon, class: 'Editathon' do
    start Date.new(2015, 1, 1)
    self.end Date.new(2015, 6, 1)
    title 'Basket-weaving edit-a-thon'
    school 'NARA'
    term 'spring 2015'
    slug 'NARA/Basket-weaving_edit-a-thon_(spring_2015)'
    passcode 'pizza'
    type 'Editathon'
    home_wiki_id 1
  end

  factory :legacy_course, class: 'LegacyCourse' do
    start Date.new(2013, 1, 1)
    self.end Date.new(2013, 6, 1)
    title 'Legacy basket-weaving'
    school 'PBR'
    term 'spring 2013'
    slug 'PRB/Legacy_basket-weaving_edit-a-thon_(spring_2013)'
    passcode 'pizza'
    type 'LegacyCourse'
    home_wiki_id 1
  end

  factory :article_scoped_program, class: 'ArticleScopedProgram' do
    start Date.new(2013, 1, 1)
    self.end Date.new(2013, 6, 1)
    title 'Only basket-weaving'
    school 'WMIT'
    term 'spring 2013'
    slug 'WMIT/Only_basket-weaving_edit-a-thon_(spring_2013)'
    passcode 'pizza'
    type 'ArticleScopedProgram'
    home_wiki_id 1
  end
end
