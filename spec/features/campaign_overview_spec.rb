# frozen_string_literal: true

require 'rails_helper'

campaign_course_count = 10

module ResetLocale
  RSpec.configuration.before do
    I18n.locale = 'en'
  end
end

describe 'campaign overview page', type: :feature, js: true do
  let(:slug)  { 'spring_2016' }
  let(:user)  { create(:user) }
  let(:campaign) do
    create(:campaign,
           title: 'Spring 2016 campaign',
           slug: slug,
           description: 'This is the best campaign')
  end

  describe 'header' do
    before do
      campaign_two = create(:campaign_two)

      (1..campaign_course_count).each do |i|
        course1 = create(:course,
                         id: i,
                         title: "course #{i}",
                         slug: "school/course_#{i}_(term)",
                         start: '2014-01-01'.to_date,
                         end: Time.zone.today + 2.days)
        course1.campaigns << campaign
        course2 = create(:course,
                         id: (i + campaign_course_count),
                         title: "course #{i + campaign_course_count}",
                         slug: "school/course_#{i + campaign_course_count}_(term)",
                         start: '2014-01-01'.to_date,
                         end: Time.zone.today + 2.days)
        course2.campaigns << campaign_two

        # STUDENTS, one per course
        create(:user, username: "user#{i}", id: i, trained: true)
        create(:courses_user,
               id: i,
               course_id: i,
               user_id: i,
               role: CoursesUsers::Roles::STUDENT_ROLE)

        # INSTRUCTORS, one per course
        create(:user, username: "instructor#{i}", id: i + campaign_course_count, trained: true)
        create(:courses_user,
               id: i + campaign_course_count,
               course_id: i,
               user_id: i + campaign_course_count,
               role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        # The instructors are also enrolled as students.
        create(:courses_user,
               id: i + campaign_course_count * 2,
               course_id: i,
               user_id: i + campaign_course_count,
               role: CoursesUsers::Roles::STUDENT_ROLE)

        # article = create(:article,
        #                  id: i,
        #                  title: 'Selfie',
        #                  namespace: 0)
        # create(:articles_course,
        #        course_id: course1.id,
        #        article_id: article.id)
        # create(:revision,
        #        id: i,
        #        user_id: i,
        #        article_id: i,
        #        date: 6.days.ago,
        #        characters: 9000)
      end
      Course.update_all_caches
    end

    it 'should display stats accurately' do
      visit "/campaigns/#{campaign.slug}/overview"

      # Number of courses
      course_count = Campaign.find(campaign.id).courses.count
      stat_text = "#{course_count} #{I18n.t('courses.course_description')}"
      expect(page.find('.stat-display')).to have_content stat_text

      # Number of students
      # one non-instructor student per course and one instructor-student per course
      student_count = campaign_course_count * 2
      stat_text = "#{student_count} #{I18n.t('courses.students')}"
      expect(page.find('.stat-display')).to have_content stat_text

      # Words added
      word_count = WordCount.from_characters Course.all.sum(:character_sum)
      stat_text = "#{word_count} #{I18n.t('metrics.word_count')}"
      expect(page.find('.stat-display')).to have_content stat_text

      # Views
      view_count = Course.all.sum(:view_sum)
      stat_text = "#{view_count} #{I18n.t('metrics.view_count_description')}"
      expect(page.find('.stat-display')).to have_content stat_text
    end

    describe 'non-default locales' do
      include ResetLocale

      it 'should switch languages' do
        visit "/campaigns/#{campaign.slug}/overview?locale=qqq"
        expect(page.find('.stat-display')).to have_content 'Long label for the number'
      end

      it 'falls back when locale is not available' do
        visit "/campaigns/#{campaign.slug}/overview?locale=aa"
        expect(page.find('.stat-display')).to have_content '20 Students'
      end

      # TODO: Test somewhere that has access to the request.
      # it 'gets preferred language from header' do
      #   request.env['HTTP_ACCEPT_LANGUAGE'] = 'es-MX,fr'
      #   get ':index'
      #   expect(response).to have_content '10 Estudiantes'
      # end
    end
  end

  context 'as an user' do
    it 'should not show the edit buttons' do
      login_as(user, scope: user)
      visit "/campaigns/#{campaign.slug}"
      expect(page).to have_no_css('.rails_editable-edit')
      expect(page).to have_no_css('.campaign-create')
    end
  end

  context 'as a campaign organizer' do
    before do
      create(:campaigns_user, user_id: user.id, campaign_id: campaign.id,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      login_as(user, scope: :user)
      visit "/campaigns/#{campaign.slug}/edit"
    end

    describe 'campaign description' do
      it 'shows the description input field when in edit mode' do
        find('.campaign-description .rails_editable-edit').click
        find('#campaign_description', visible: true)
      end

      it 'updates the campaign when you click save' do
        new_description = 'This is my new description'
        find('.campaign-description .rails_editable-edit').click
        fill_in('campaign_description', with: new_description)
        find('.campaign-description .rails_editable-save').click
        expect(page).to have_content('Campaign updated')
        expect(campaign.reload.description).to eq(new_description)
      end
    end

    describe 'campaign details' do
      it 'shows add organizers button and title field when in edit mode' do
        find('.campaign-details .rails_editable-edit').click
        find('.campaign-details .button.plus', visible: true)
        find('#campaign_title', visible: true)
      end

      it 'updates the campaign when you click save' do
        new_title = 'My even more awesome campaign 2016'
        find('.campaign-details .rails_editable-edit').click
        fill_in('campaign_title', with: new_title)
        find('.campaign-details .rails_editable-save').click
        expect(page).to have_content('Campaign updated')
        expect(campaign.reload.title).to eq(new_title)
      end

      it 'shows an error if you try to add a nonexistent user as an organizer' do
        find('.campaign-details .rails_editable-edit').click
        find('.campaign-details .button.plus').click
        username = 'Nonexistent user'
        fill_in('username', with: username)
        find('.add-organizer-button').click
        expect(page).to have_content(I18n.t('courses.error.user_exists', username: username))
        expect(campaign.reload.organizers.collect(&:username)).not_to include(username)
      end

      context 'start and end dates' do
        it "hides the start and end dates unless the 'Use start and end dates' is checked" do
          find('.campaign-details .rails_editable-edit').click
          find('#campaign_start', visible: false)
          find('#use_dates').click
          find('#campaign_start', visible: true)
        end

        it 'shows an error for invalid dates' do
          find('.campaign-details .rails_editable-edit').click
          find('#use_dates').click
          fill_in('campaign_start', with: '2016-01-10')
          fill_in('campaign_end', with: 'Invalid date')
          find('.campaign-details .rails_editable-save').click
          expect(page).to have_content(I18n.t('error.invalid_date', key: 'End'))
          find('#campaign_end', visible: true) # field with the error should be visible
        end

        it 'updates the date fields properly, and unsets if #use_dates is unchecked' do
          find('.campaign-details .rails_editable-edit').click
          find('#use_dates').click
          fill_in('campaign_start', with: '2016-01-10')
          fill_in('campaign_end', with: '2016-02-10')
          find('.campaign-details .rails_editable-save').click
          expect(campaign.reload.start).to eq(DateTime.civil(2016, 1, 10, 0, 0, 0))
          expect(campaign.end).to eq(DateTime.civil(2016, 2, 10, 23, 59, 59))
          click_button 'Edit'
          find('.campaign-details .rails_editable-edit').click
          find('#use_dates').click # uncheck
          find('#campaign_start', visible: false)
          find('.campaign-details .rails_editable-save').click
          find('.campaign-start', visible: false)
          expect(campaign.reload.start).to be_nil
          expect(campaign.end).to be_nil
        end
      end
    end

    describe 'campaign deletion' do
      it 'deletes the campaign when you click on delete' do
        accept_prompt(with: campaign.title) do
          find('.campaign-delete .button').click
        end
        expect(page).to have_content('has been deleted')
        expect(Campaign.find_by_slug(campaign.slug)).to be_nil
      end

      it 'throws an error if you enter the wrong campaign title when trying to delete it' do
        wrong_title = 'Not the title of the campaign'
        accept_alert(with: /"#{wrong_title}"/) do
          accept_prompt(with: wrong_title) do
            find('.campaign-delete .button').click
          end
        end
      end
    end
  end
end
