require 'rails_helper'
require "#{Rails.root}/lib/wizard_timeline_manager"

describe WizardTimelineManager do
  describe '#add_tags' do
    it 'should update a tag with the same key as an existing tag' do
      create(:course, id: 10001, timeline_start: Time.zone.today, timeline_end: Time.zone.today)
      create(:tag, id: 1, course_id: 10001, tag: 'use_sandboxes', key: 'draft_and_mainspace')

      wizard_id = 'researchwrite'
      wizard_params = { 'wizard_output' =>
                        { 'tags' =>
                          [{ tag: 'work_live', key: 'draft_and_mainspace' }] } }
      course = Course.find(10001)
      WizardTimelineManager.update_timeline_and_tags(course, wizard_id, wizard_params)
      expect(Tag.find(1).tag).to eq('work_live')
    end
  end
end
