# frozen_string_literal: true

require 'rails_helper'

describe FacilitatorStatUpdateWorker do
  let(:wiki) { Wiki.default_wiki }

  let!(:course1) do
    create(:course,
           start: 1.month.ago,
           end: 1.month.from_now,
           slug: 'School/Course1_(term)',
           revision_count: 200,
           character_sum: 40_000,
           home_wiki_id: wiki.id,
           private: false)
  end

  let!(:course2) do
    create(:course,
           start: 2.months.ago,
           end: 2.months.from_now,
           slug: 'School/Course2_(term)',
           revision_count: 300,
           character_sum: 60_000,
           home_wiki_id: wiki.id,
           private: false)
  end

  # Instructor teaching both courses
  let!(:instructor) do
    user = create(:user, username: 'FacilitatorA')
    create(:courses_user, course: course1, user: user,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:courses_user, course: course2, user: user,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    user
  end

  # Student in course1 — registered during course (new editor)
  let!(:new_student) do
    user = create(:user, username: 'NewStudent1',
                         registered_at: course1.start + 1.week)
    create(:courses_user, course: course1, user: user,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    user
  end

  # Student in course2 — registered long before course (not new editor)
  let!(:old_student) do
    user = create(:user, username: 'OldStudent1',
                         registered_at: course2.start - 1.year)
    create(:courses_user, course: course2, user: user,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    user
  end

  # Student in course2 — registered within 60 days before course start
  let!(:preregistered_student) do
    user = create(:user, username: 'PreregisteredStudent1',
                         registered_at: course2.start - 3.weeks)
    create(:courses_user, course: course2, user: user,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    user
  end

  describe '#perform' do
    before do
      allow(Features).to receive(:wiki_ed?).and_return(false)
    end

    it 'does not run on Wiki Ed dashboard' do
      allow(Features).to receive(:wiki_ed?).and_return(true)
      expect { described_class.new.perform }.not_to change(FacilitatorStat, :count)
    end

    it 'creates a facilitator stat record' do
      expect { described_class.new.perform }.to change(FacilitatorStat, :count).by(1)
    end

    it 'computes correct program counts' do
      described_class.new.perform
      stat = FacilitatorStat.find_by(user_id: instructor.id, snapshot_date: Time.zone.today)

      expect(stat.total_programs_count).to eq(2)
      expect(stat.active_programs_count).to eq(2)  # both are strictly_current
    end

    it 'computes correct edit and character sums' do
      described_class.new.perform
      stat = FacilitatorStat.find_by(user_id: instructor.id, snapshot_date: Time.zone.today)

      expect(stat.total_edits).to eq(500)               # 200 + 300
      expect(stat.total_characters_added).to eq(100_000) # 40000 + 60000
    end

    it 'counts students across all facilitator courses' do
      described_class.new.perform
      stat = FacilitatorStat.find_by(user_id: instructor.id, snapshot_date: Time.zone.today)

      expect(stat.total_students_count).to eq(3)  # new + old + prereg
    end

    it 'counts new editors with and without preregistration window' do
      described_class.new.perform
      stat = FacilitatorStat.find_by(user_id: instructor.id, snapshot_date: Time.zone.today)

      # new_student registered during course → counted in both
      # preregistered_student registered 3 weeks before → counted in with_preregistration only
      # old_student registered 1 year before → NOT counted in either
      expect(stat.new_editors_count).to eq(1)
      expect(stat.new_editors_count_with_preregistration).to eq(2)
    end

    it 'marks facilitator as active in last year' do
      described_class.new.perform
      stat = FacilitatorStat.find_by(user_id: instructor.id, snapshot_date: Time.zone.today)

      expect(stat.active_in_last_year).to be true
    end

    it 'upserts when run twice on the same day' do
      described_class.new.perform
      described_class.new.perform
      count = FacilitatorStat.where(user_id: instructor.id,
                                     snapshot_date: Time.zone.today).count
      expect(count).to eq(1)
    end

    it 'falls back to 0 for missing metrics' do
      empty_course = create(:course, start: 1.month.ago, end: 1.month.from_now,
                                     slug: 'Empty', revision_count: 0, character_sum: 0,
                                     private: false)
      empty_instructor = create(:user, username: 'EmptyInst')
      create(:courses_user, course: empty_course, user: empty_instructor,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

      described_class.new.perform
      stat = FacilitatorStat.find_by(user_id: empty_instructor.id, snapshot_date: Time.zone.today)
      expect(stat.total_students_count).to eq(0)
      expect(stat.new_editors_count).to eq(0)
    end

    it 'excludes private courses' do
      private_course = create(:course, start: 1.month.ago, end: 1.month.from_now,
                                       slug: 'Private', private: true)
      private_instructor = create(:user, username: 'PrivateInst')
      create(:courses_user, course: private_course, user: private_instructor,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

      described_class.new.perform
      expect(FacilitatorStat.find_by(user_id: private_instructor.id)).to be_nil
    end

    it 'sets active_in_last_year to false if no recent courses' do
      old_course = create(:course, start: 2.years.ago, end: 13.months.ago,
                                   slug: 'Old', private: false)
      old_instructor = create(:user, username: 'OldInst')
      create(:courses_user, course: old_course, user: old_instructor,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

      described_class.new.perform
      stat = FacilitatorStat.find_by(user_id: old_instructor.id, snapshot_date: Time.zone.today)
      expect(stat.active_in_last_year).to be false
    end
  end
end
