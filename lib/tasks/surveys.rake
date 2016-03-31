require 'factory_girl'

namespace :surveys do
  Dir["/spec/factories/*.rb"].each {|file| require file }
  include FactoryGirl::Syntax::Methods
  desc 'Create Survey with Basic Questions for Testing'
  task build_basic_survey: :environment do
    group_name = "Basic Question Types"
    Rapidfire::QuestionGroup.destroy(Rapidfire::QuestionGroup.find_by(:name => group_name).id)
    test_group = create(:question_group, name: group_name)
    test_survey = create(:survey)
    test_survey.rapidfire_question_groups << test_group
    test_survey.save
    create(:q_checkbox, question_group_id: test_group.id)
    create(:q_long, question_group_id: test_group.id)
    create(:q_radio, question_group_id: test_group.id)
    create(:q_select, question_group_id: test_group.id)
    create(:q_short, question_group_id: test_group.id)
    create(:q_rangeinput, question_group_id: test_group.id)
  end

  desc 'Create Survey with Conditional Questions for Testing'
  task build_conditional_survey: :environment do
    group_name = "Conditional Question Types"
    # Rapidfire::QuestionGroup.destroy(Rapidfire::QuestionGroup.find_by(:name => group_name).id)
    test_group = create(:question_group, name: group_name)
    test_survey = create(:survey, name: "Conditional Question Survey")
    test_survey.rapidfire_question_groups << test_group
    test_survey.save
    question_params = {question_group_id: test_group.id}
    # Equality Conditional
    options = ["Female", "Mail"]
    radio_parent = create(:q_radio, question_params.merge({
           answer_options: options.join("\r\n")}))
    create(:q_radio, question_params.merge({
            answer_options:    "yes\r\nno\r\n",
            conditionals:      "#{radio_parent.id}|=|#{options[0]}"}))
    create(:q_radio,
            question_params.merge({
            answer_options:  "good\r\nbad\r\n",
            conditionals: "#{radio_parent.id}|=|#{options[1]}"}))
    # Presence Conditional
    presence_parent = create(:q_long, question_params)
    create(:q_radio, question_params.merge({
            answer_options:    "yes\r\nno\r\n",
            conditionals:      "#{presence_parent.id}|*presence"}))
    # Comparison Conditional
    comparison_parent = create(:q_rangeinput, question_group_id: test_group.id)
    create(:q_long, question_params.merge(conditionals: "#{comparison_parent.id}|>=|50"))
  end

  desc 'Find CoursesUsers ready to receive surveys and create a SurveyNotification for each'
  task create_notifications: :environment do
    include SurveyAssignmentsHelper
    SurveyAssignment.published.each do |survey_assignment|
      survey_assignment.courses_users_ready_for_survey.each do |courses_user|
        course = Course.find(courses_user.course_id)
        notification = SurveyNotification.new(
          :courses_user_id => courses_user.id,
          :survey_assignment_id => survey_assignment.id,
          :course_id => course.id
        )
        notification.save
      end
    end
  end

  desc 'Find SurveyNotifications that haven\'t been sent and send them'
  task send_notifications: :environment do
    SurveyNotification.all.each do |notification|
      notification.send_email
    end
  end
end
