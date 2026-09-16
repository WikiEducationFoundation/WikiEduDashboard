# frozen_string_literal: true

require 'rails_helper'

describe CoursesPresenter do
  describe '#search_courses with a privacy-mode course' do
    let(:course) do
      create(:course, title: obfuscated_title, school: obfuscated_school, term: 'Fall 2026',
                      slug: obfuscated_slug('Fall 2026'))
    end
    let(:instructor) { create(:user, username: 'Instructor') }
    let(:presenter) { described_class.new(current_user:, courses_list: Course.all) }

    before do
      create(:confidential_course_detail, course:, real_title: 'Introduction to Biology',
                                          real_school: 'State University')
      create(:courses_user, course:, user: instructor,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    context 'when the searcher is not an admin' do
      let(:current_user) { instructor }

      it 'does not match the real institution' do
        expect(presenter.search_courses('State University')).to be_empty
      end

      it 'does not match the real title' do
        expect(presenter.search_courses('Introduction to Biology')).to be_empty
      end

      it 'still matches the obfuscated values' do
        expect(presenter.search_courses(obfuscated_school)).to include(course)
      end
    end

    context 'when the searcher is an admin' do
      let(:current_user) { create(:admin, username: 'Admin') }

      it 'matches the real institution' do
        expect(presenter.search_courses('State University')).to include(course)
      end

      it 'matches the real title' do
        expect(presenter.search_courses('Introduction to Biology')).to include(course)
      end

      it 'still matches an ordinary course by its title' do
        other = create(:course, title: 'Ordinary', school: 'Open U', term: 'Fall 2026',
                                slug: 'Open_U/Ordinary_(Fall_2026)')
        create(:courses_user, course: other, user: instructor,
                              role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        expect(presenter.search_courses('Ordinary')).to include(other)
      end
    end
  end
end
