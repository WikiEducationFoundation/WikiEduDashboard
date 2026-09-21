# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'retained_editors rake tasks' do
  before do
    Rake.application.rake_require('retained_editors', [Rails.root.join('lib/tasks').to_s])
    Rake::Task.define_task(:environment)
  end

  describe 'retained_editors:check' do
    it 'invokes RetainedEditorCheckWorker#perform' do
      allow_any_instance_of(RetainedEditorCheckWorker).to receive(:perform).and_return(5)
      expect { Rake::Task['retained_editors:check'].invoke }
        .to output(/Processed 5 records/).to_stdout
      Rake::Task['retained_editors:check'].reenable
    end
  end

  describe 'retained_editors:backfill' do
    let(:course) { create(:course, start: 90.days.ago, end: 70.days.ago, private: false) }
    let(:user) { create(:user, registered_at: 80.days.ago) }

    before do
      create(:courses_user, course: course, user: user,
                            role: CoursesUsers::Roles::STUDENT_ROLE,
                            retained_after_course: nil)
    end

    it 'processes eligible historical courses' do
      allow_any_instance_of(RetainedEditorCheckWorker)
        .to receive(:check_course_new_editors).and_return(1)
      expect { Rake::Task['retained_editors:backfill'].invoke }
        .to output(/Historical backfill complete!/).to_stdout
      Rake::Task['retained_editors:backfill'].reenable
    end

    it 'stops gracefully when the API is down (nil return)' do
      allow_any_instance_of(RetainedEditorCheckWorker)
        .to receive(:check_course_new_editors).and_return(nil)
      expect { Rake::Task['retained_editors:backfill'].invoke }
        .to output(/API appears down, stopping backfill/).to_stdout
      Rake::Task['retained_editors:backfill'].reenable
    end
  end
end
