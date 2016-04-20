require 'rails_helper'

describe QuestionGroupsHelper, type: :helper do
  describe '#check_conditionals' do
    before :each do
      @tag = create(:tag, tag: 'pizza')
      @cohort = create(:cohort)
      @survey = build_stubbed(:survey)
      @survey_assignment = build_stubbed(:survey_assignment, survey_id: @survey)
    end

    it 'returns true it question_group has no tags or cohorts' do
      @course = create(:course)
      @notification = build_stubbed(
        :survey_notification,
        survey_assignment_id: @survey_assignment.id,
        course_id: @course.id
      )
      question_group = build_stubbed(:question_group, tags: '')
      expect(check_conditionals(question_group)).to be true
    end

    it 'returns true if question_group tags match course tags' do
      @course = create(:course, tags: [@tag])
      @notification = build_stubbed(
        :survey_notification,
        survey_assignment_id: @survey_assignment.id,
        course_id: @course.id
      )
      question_group = build_stubbed(:question_group, tags: @tag.tag)
      expect(check_conditionals(question_group)).to be true
    end

    it 'returns false if question_group tags don\'t match course tags' do
      @course = create(:course, tags: [@tag])
      tag = create(:tag, tag: 'coffee')
      @notification = build_stubbed(
        :survey_notification,
        survey_assignment_id: @survey_assignment.id,
        course_id: @course.id
      )
      question_group = build_stubbed(:question_group, tags: tag.tag)
      expect(check_conditionals(question_group)).to be false

      question_group = build_stubbed(:question_group, tags: [tag.tag.to_s, 'tea'].join(','))
      expect(check_conditionals(question_group)).to be false
    end

    it 'returns true if question_group cohorts match course cohorts' do
      @course = create(:course)
      @course.cohorts << @cohort
      @notification = build_stubbed(
        :survey_notification,
        survey_assignment_id: @survey_assignment.id,
        course_id: @course.id
      )
      question_group = create(:question_group, tags: '')
      question_group.cohorts << @cohort

      expect(check_conditionals(question_group)).to be true
    end

    it 'returns false if question_group cohorts don\'t match course cohorts' do
      @course = create(:course)
      @course.cohorts << @cohort
      @notification = build_stubbed(
        :survey_notification,
        survey_assignment_id: @survey_assignment.id,
        course_id: @course.id
      )
      cohort = create(:cohort)
      question_group = create(:question_group, tags: '')
      question_group.cohorts << cohort

      expect(check_conditionals(question_group)).to be false
    end

    it 'returns true if question_group cohorts and tags match those of the course' do
      @course = create(:course, tags: [@tag])
      @course.cohorts << @cohort
      @notification = build_stubbed(
        :survey_notification,
        survey_assignment_id: @survey_assignment.id,
        course_id: @course.id
      )
      question_group = create(:question_group, tags: @tag.tag)
      question_group.cohorts << @cohort
      expect(check_conditionals(question_group)).to be true
    end
  end
end
