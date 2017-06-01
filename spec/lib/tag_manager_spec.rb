# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/tag_manager"

describe TagManager do
  describe '#initial_tags' do
    let(:course) { create(:course) }
    let(:course2) { create(:course, slug: 'second_course') }
    let(:creator) { create(:user) }
    let(:subject) { course.tags.first.tag }

    context 'when courses must be approved' do
      it 'adds a returning_instructor tag if the creator is a returning instructor' do
        expect(creator).to receive(:returning_instructor?).and_return(true)
        TagManager.new(course).initial_tags(creator: creator)
        expect(subject).to eq('returning_instructor')
      end

      it 'adds a first_time_instructor tag if the creator is not a returning instructor' do
        expect(creator).to receive(:returning_instructor?).and_return(false)
        TagManager.new(course).initial_tags(creator: creator)
        expect(subject).to eq('first_time_instructor')
      end
    end

    context 'when open course creation is enabled' do
      before do
        allow(Features).to receive(:open_course_creation?).and_return(true)
        create(:courses_user, user: creator, course: course,
                              role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      end

      it 'adds a returning_instructor tag if the creator has more than one course' do
        create(:courses_user, user: creator, course: course2,
                              role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        TagManager.new(course).initial_tags(creator: creator)
        expect(subject).to eq('returning_instructor')
      end

      it 'adds a first_time_instructor tag if the creator has only one course' do
        TagManager.new(course).initial_tags(creator: creator)
        expect(subject).to eq('first_time_instructor')
      end
    end
  end
end
