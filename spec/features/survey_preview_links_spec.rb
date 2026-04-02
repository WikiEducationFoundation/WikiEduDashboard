# frozen_string_literal: true

require 'rails_helper'

describe 'Survey preview links', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:survey) { create(:survey) }

  before { login_as(admin) }

  describe 'survey with no question groups' do
    it 'shows no preview link' do
      survey # ensure record exists before page renders
      visit '/surveys'
      within('li.survey__admin-row--survey') do
        expect(page).not_to have_link('Preview')
      end
    end
  end

  describe 'survey with a question group but no tagged groups' do
    let(:question_group) { create(:question_group, tags: '') }

    before { survey.rapidfire_question_groups << question_group }

    context 'when a recent course with articles exists' do
      let(:course) { create(:course, end: 1.month.from_now) }
      let(:article) { create(:article) }

      before { create(:articles_course, course: course, article: article) }

      it 'shows a single "Preview (default course)" link' do
        visit '/surveys'
        within('li.survey__admin-row--survey') do
          expect(page).to have_link('Preview')
          expect(page).not_to have_button('Preview ▾')
        end
      end
    end

    context 'when no courses exist at all' do
      it 'shows a single "Preview (select course)" fallback link' do
        visit '/surveys'
        within('li.survey__admin-row--survey') do
          expect(page).to have_link('Preview')
          expect(page).not_to have_button('Preview ▾')
        end
      end
    end
  end

  describe 'survey with tagged question groups' do
    let(:first_time_group) do
      create(:question_group, name: 'First Timer Questions', tags: 'first_time_instructor')
    end
    let(:returning_group) do
      create(:question_group, name: 'Returning Instructor Questions', tags: 'returning_instructor')
    end

    before do
      survey.rapidfire_question_groups << first_time_group
      survey.rapidfire_question_groups << returning_group
    end

    context 'when courses with those tags exist' do
      let(:first_time_course) { create(:course, end: 1.month.from_now) }
      let(:returning_course) { create(:basic_course, end: 2.months.from_now) }

      before do
        create(:tag, course: first_time_course, tag: 'first_time_instructor')
        create(:tag, course: returning_course, tag: 'returning_instructor')
      end

      it 'shows a dropdown with one link per tag' do
        visit '/surveys'
        within('li.survey__admin-row--survey') do
          expect(page).to have_button('Preview ▾')
          click_button 'Preview ▾'
          expect(page).to have_css('.preview-link',
                                   text: "Preview with 'first_time_instructor' tag")
          expect(page).to have_css('.preview-link',
                                   text: "Preview with 'returning_instructor' tag")
          expect(page).to have_css('.course-name', text: first_time_course.title)
          expect(page).to have_css('.question-groups', text: 'First Timer Questions')
        end
      end
    end

    context 'when no courses with the tags exist' do
      it 'falls back to a single generic preview link' do
        visit '/surveys'
        within('li.survey__admin-row--survey') do
          expect(page).to have_link('Preview')
          expect(page).not_to have_button('Preview ▾')
        end
      end
    end

    context 'when only one tag has a matching course' do
      let(:first_time_course) { create(:course, end: 1.month.from_now) }

      before { create(:tag, course: first_time_course, tag: 'first_time_instructor') }

      it 'shows a single link for the matched tag only' do
        visit '/surveys'
        within('li.survey__admin-row--survey') do
          expect(page).to have_link('Preview')
          expect(page).not_to have_button('Preview ▾')
        end
      end
    end
  end

  describe 'survey with a question group tagged with multiple tags' do
    let(:multi_tag_group) do
      create(:question_group, name: 'Multi-Tag Group',
                              tags: 'first_time_instructor, returning_instructor')
    end

    before { survey.rapidfire_question_groups << multi_tag_group }

    context 'when courses with both tags exist' do
      let(:first_time_course) { create(:course, end: 1.month.from_now) }
      let(:returning_course) { create(:basic_course, end: 2.months.from_now) }

      before do
        create(:tag, course: first_time_course, tag: 'first_time_instructor')
        create(:tag, course: returning_course, tag: 'returning_instructor')
      end

      it 'shows a dropdown link for each tag, both referencing the same group' do
        visit '/surveys'
        within('li.survey__admin-row--survey') do
          expect(page).to have_button('Preview ▾')
          click_button 'Preview ▾'
          expect(page).to have_css('.preview-link', count: 2)
          expect(page).to have_css('.question-groups', text: 'Multi-Tag Group', count: 2)
        end
      end
    end
  end
end
