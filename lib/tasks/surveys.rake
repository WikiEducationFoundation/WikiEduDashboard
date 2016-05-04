require 'factory_girl_rails'
require "#{Rails.root}/lib/surveys/survey_notifications_manager"

namespace :surveys do
  Dir['/spec/factories/*.rb'].each { |file| require file }
  include FactoryGirl::Syntax::Methods

  desc 'Create All Testing Surveys'
  task batch_build: :environment do
    Rake::Task['surveys:build_basic_survey'].invoke
    Rake::Task['surveys:build_conditional_survey'].invoke
    Rake::Task['surveys:build_matrix_survey'].invoke
    Rake::Task['surveys:build_course_data_survey'].invoke
  end

  desc 'Create Survey with Basic Questions for Testing'
  task build_basic_survey: :environment do
    group_name = 'Basic Question Types'
    test_group = create(:question_group, name: group_name)
    test_survey = create(:survey)
    test_survey.rapidfire_question_groups << test_group
    test_survey.save
    create(:q_checkbox, question_group_id: test_group.id, validation_rules: { presence: '1' })
    create(:q_long, question_group_id: test_group.id, validation_rules: { presence: '1' })
    create(:q_radio, question_group_id: test_group.id, validation_rules: { presence: '1' })
    create(:q_select, question_group_id: test_group.id, validation_rules: { presence: '1' })
    create(:q_short, question_group_id: test_group.id, validation_rules: { presence: '1' })
    create(:q_rangeinput, question_group_id: test_group.id)
  end

  desc 'Create Survey with Conditional Questions for Testing'
  task build_conditional_survey: :environment do
    group_name = 'Conditional Question Types'
    test_group = create(:question_group, name: group_name)
    test_survey = create(:survey, name: 'Conditional Question Survey')
    test_survey.rapidfire_question_groups << test_group
    test_survey.save
    question_params = { question_group_id: test_group.id }
    # Equality Conditional
    options = %w(Female Mail)
    radio_parent = create(:q_radio, question_params.merge(answer_options: options.join("\r\n")))
    create(:q_radio, question_params.merge(answer_options:    "yes\r\nno\r\n",
                                           conditionals:      "#{radio_parent.id}|=|#{options[0]}"))
    create(:q_radio,
           question_params.merge(answer_options:  "good\r\nbad\r\n",
                                 conditionals: "#{radio_parent.id}|=|#{options[1]}"))
    # Presence Conditional
    presence_parent = create(:q_long, question_params)
    create(:q_radio, question_params.merge(answer_options:    "yes\r\nno\r\n",
                                           conditionals:      "#{presence_parent.id}|*presence"))
    # Comparison Conditional
    comparison_parent = create(:q_rangeinput, question_group_id: test_group.id)
    create(:q_long, question_params.merge(conditionals: "#{comparison_parent.id}|>=|50"))
  end

  desc 'Create Survey with Matrix (Grouped) Questions for Testing'
  task build_matrix_survey: :environment do
    group_name = 'Matrix Questions'
    test_group = create(:question_group, name: group_name)
    test_survey = create(:survey, name: 'Matrix Question Survey')
    test_survey.rapidfire_question_groups << test_group
    test_survey.save
    question_params = {
      question_group_id: test_group.id,
      answer_options:  "Unlikely\r\nPossibly\r\nVery Likely\r\nDefinitely",
      validation_rules: { grouped: '1', grouped_question: 'How likely are you to do these things?' }
    }
    create(:q_radio, question_params.merge(question_text: 'Sky Diving'))
    create(:q_radio, question_params.merge(question_text: 'Rob a bank'))
    create(:q_radio, question_params.merge(question_text: 'Write a computer virus'))
    create(:q_radio, question_params.merge(question_text: 'Walk across the US'))
  end

  desc 'Create Course-Specific Questions for Testing'
  task build_course_data_survey: :environment do
    group_name = 'Course Data Questions'
    test_group = create(:question_group, name: group_name)
    test_survey = create(:survey, name: 'Course Data Question Survey')
    test_survey.rapidfire_question_groups << test_group
    question_params = { question_group_id: test_group.id, answer_options: '' }
    create(:q_select, question_params.merge(question_text: 'Select a student',
                                            course_data_type: 'Students'))
    create(:q_radio, question_params.merge(question_text: 'Select a WikiEdu Staff Member',
                                           course_data_type: 'WikiEdu Staff'))
    create(:q_checkbox, question_params.merge(question_text: 'Select an Article',
                                              course_data_type: 'Articles'))
  end

  desc 'Find CoursesUsers ready to receive surveys and create a SurveyNotification for each'
  task create_notifications: :environment do
    SurveyNotificationsManager.create_notifications
  end

  desc 'Find SurveyNotifications that haven\'t been sent and send them'
  task send_notifications: :environment do
    SurveyNotification.active.each(&:send_email)
  end
end
