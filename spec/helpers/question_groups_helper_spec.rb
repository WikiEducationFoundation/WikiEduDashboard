# frozen_string_literal: true

require 'rails_helper'

describe QuestionGroupsHelper, type: :helper do
  describe '#course_meets_conditions_for_question_group?' do
    before :each do
      @tag = create(:tag, tag: 'pizza')
      @campaign = create(:campaign)
      @survey = build_stubbed(:survey)
      @survey_assignment = build_stubbed(:survey_assignment, survey_id: @survey)
    end

    it 'returns true it question_group has no tags or campaigns' do
      @course = create(:course)
      @notification = build_stubbed(
        :survey_notification,
        survey_assignment_id: @survey_assignment.id,
        course_id: @course.id
      )
      question_group = build_stubbed(:question_group, tags: '')
      expect(course_meets_conditions_for_question_group?(question_group)).to be true
    end

    it 'returns true if question_group tags match course tags' do
      @course = create(:course, tags: [@tag])
      @notification = build_stubbed(
        :survey_notification,
        survey_assignment_id: @survey_assignment.id,
        course_id: @course.id
      )
      question_group = build_stubbed(:question_group, tags: @tag.tag)
      expect(course_meets_conditions_for_question_group?(question_group)).to be true
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
      expect(course_meets_conditions_for_question_group?(question_group)).to be false

      question_group = build_stubbed(:question_group, tags: [tag.tag.to_s, 'tea'].join(','))
      expect(course_meets_conditions_for_question_group?(question_group)).to be false
    end

    it 'returns true if question_group campaigns match course campaigns' do
      @course = create(:course)
      @course.campaigns << @campaign
      @notification = build_stubbed(
        :survey_notification,
        survey_assignment_id: @survey_assignment.id,
        course_id: @course.id
      )
      question_group = create(:question_group, tags: '')
      question_group.campaigns << @campaign

      expect(course_meets_conditions_for_question_group?(question_group)).to be true
    end

    it 'returns false if question_group campaigns don\'t match course campaigns' do
      @course = create(:course)
      @course.campaigns << @campaign
      @notification = build_stubbed(
        :survey_notification,
        survey_assignment_id: @survey_assignment.id,
        course_id: @course.id
      )
      campaign = create(:campaign, title: 'My Second Campaign')
      question_group = create(:question_group, tags: '')
      question_group.campaigns << campaign

      expect(course_meets_conditions_for_question_group?(question_group)).to be false
    end

    it 'returns true if question_group campaigns and tags match those of the course' do
      @course = create(:course, tags: [@tag])
      @course.campaigns << @campaign
      @notification = build_stubbed(
        :survey_notification,
        survey_assignment_id: @survey_assignment.id,
        course_id: @course.id
      )
      question_group = create(:question_group, tags: @tag.tag)
      question_group.campaigns << @campaign
      expect(course_meets_conditions_for_question_group?(question_group)).to be true
    end
  end
end
