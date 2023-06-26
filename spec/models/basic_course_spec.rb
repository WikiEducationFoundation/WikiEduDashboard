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
#  view_sum              :bigint           default(0)
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
#  syllabus_file_size    :bigint
#  syllabus_updated_at   :datetime
#  home_wiki_id          :integer
#  recent_revision_count :integer          default(0)
#  needs_update          :boolean          default(FALSE)
#  chatroom_id           :string(255)
#  flags                 :text(65535)
#  level                 :string(255)
#  private               :boolean          default(FALSE)
#  withdrawn             :boolean          default(FALSE)
#  references_count      :integer          default(0)
#
require 'rails_helper'

describe BasicCourse do
  let(:flags) { nil }
  let(:subject) { create(:basic_course, flags:) }

  describe '#assignment_edits_enabled?' do
    it 'returns true by default' do
      expect(subject.assignment_edits_enabled?).to eq(true)
    end

    context 'with edit_settings flag' do
      let(:flags) do
        {
          'edit_settings' => { 'assignment_edits_enabled' => false }
        }
      end

      it 'returns the value of the set flag' do
        expect(subject.assignment_edits_enabled?).to eq(false)
      end
    end
  end
end
