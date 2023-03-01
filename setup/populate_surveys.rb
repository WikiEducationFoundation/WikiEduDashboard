# frozen_string_literal: true

def populate_courses
  clear_courses
  populate_users
  
  n_courses = ENV['courses'] || 100
  to_insert = []
  n_courses.to_i.times do |i|
    to_insert << {
      title: "generated course",
      slug: "course-#{i}",
    }
  end
  Course.insert_all(to_insert)
  courses_users = []
  to_insert.each_with_index do |course, i|
    course_id = Course.find_by(slug: "course-#{i}").id
    1..20.times do |i|
      user_id = User.where(email: "generated user").order("RAND()").first.id
      courses_users << {
        course_id: course_id,
        user_id: user_id,
        role: 0
      }
    end
  end
  CoursesUsers.insert_all(courses_users)
end

def populate_users
  clear_users
  n_users = ENV['users'] || 100
  to_insert = []
  n_users.to_i.times do |i|
    to_insert << {
      username: "generated user #{i}",
      email: "generated user"
    }
  end
  User.insert_all(to_insert)
end

def clear_users
  User.where(email: "generated user").delete_all
end

def clear_courses
  Course.where(title: "generated course").destroy_all
end

def populate_survey_questions
  clear_survey_questions
  clear_survey
  clear_survey_notifications

  question_group_1 = Rapidfire::QuestionGroup.find_or_create_by(
    name: "generated group 1",
    tags: ""
  )
  question_group_2 = Rapidfire::QuestionGroup.find_or_create_by(
    name: "generated group 2",
    tags: ""
  )

  to_create = []
  survey_notifications = []
  
  n_questions = ENV['questions'] || 100

  1..n_questions.to_i.times do |i|
    to_create << {
      question_group_id: n_questions % 2 == 0 ? question_group_1.id : question_group_2.id, 
      question_text: "Question #{i}", 
      type: "Rapidfire::Questions::Checkbox", 
      position: i,
      answer_options: "A\r\nB\r\nC\r\nD",
      validation_rules: {
        presence: '1',
        grouped: '0',
        grouped_question: '',
        minimum: '',
        maximum: '',
        range_minimum: '',
        range_maximum: '',
        range_increment: '',
        range_divisions: '',
        range_format: '',
        greater_than_or_equal_to: '',
        less_than_or_equal_to: ''
      }
    }
  end
  
  generated_survey = Survey.create(
    name: "generated survey",
    open: 1,
    closed: 0
  )

  assignment = SurveyAssignment.create(
    survey_id: generated_survey.id,
    courses_user_role: 0,
  )

  
  Rapidfire::Question.insert_all(to_create)
  
  SurveysQuestionGroup.create(
    survey_id: generated_survey.id,
    rapidfire_question_group_id: question_group_1.id,
    position: 1
  )
  SurveysQuestionGroup.create(
    survey_id: generated_survey.id,
    rapidfire_question_group_id: question_group_2.id,
    position: 2
  )

  User.where(email: "generated user").includes(:courses_users).each do |user|
    user.courses_users.each do |courses_user|
      survey_notifications << {
        survey_assignment_id: assignment.id,
        courses_users_id: courses_user.id,
        course_id: courses_user.course_id,
        completed: 1,
      }
    end
  end
  SurveyNotification.insert_all(survey_notifications)
end

def populate_survey_answers
  clear_survey_answers
  question_group_1 = Rapidfire::QuestionGroup.find_by(name: "generated group 1")
  question_group_2 = Rapidfire::QuestionGroup.find_by(name: "generated group 2")

  to_create = []

  n_responses = ENV['responses'] || 200

  1..n_responses.to_i.times do |round|
    question_group_id = round % 2 == 0 ? question_group_1.id : question_group_2.id
    answer_group = Rapidfire::AnswerGroup.create(
      question_group_id: question_group_id,
      user_id: User.where(email: 'generated user').order('RAND()').first.id,
    )
    Rapidfire::Question.where(
      question_group_id: question_group_id,
    ).each do |question|
      to_create << {
        answer_group_id: answer_group.id,
        question_id: question.id,
        answer_text: ["A","B","C","D"].sample
      }
    end
  end
  Rapidfire::Answer.insert_all(to_create)
end

def clear_survey_answers 
  question_group_1 = Rapidfire::QuestionGroup.find_by(name: "generated group 1")
  question_group_2 = Rapidfire::QuestionGroup.find_by(name: "generated group 2")

  to_delete = []
  if question_group_1
    Rapidfire::AnswerGroup.where(
      question_group_id: question_group_1.id,
    ).each do |answer_group|
      Rapidfire::Answer.where(
        answer_group_id: answer_group.id
      ).each do |answer|
        to_delete << answer
      end
    end
  end
  if question_group_2
    Rapidfire::AnswerGroup.where(
      question_group_id: question_group_2.id,
    ).each do |answer_group|
      Rapidfire::Answer.where(
        answer_group_id: answer_group.id
      ).each do |answer|
        to_delete << answer
      end
    end
  end
  Rapidfire::Answer.delete(to_delete)
end

def clear_survey_questions
  question_group_1 = Rapidfire::QuestionGroup.find_by(name: "generated group 1")
  question_group_2 = Rapidfire::QuestionGroup.find_by(name: "generated group 2")

  if question_group_1
    Rapidfire::Question.where(
      question_group_id: question_group_1.id,
    ).destroy_all
  end
  if question_group_2
    Rapidfire::Question.where(
      question_group_id: question_group_2.id,
    ).destroy_all
  end
end

def clear_survey
  survey = Survey.find_by(name: "generated survey")
  return unless survey

  SurveysQuestionGroup.where(survey_id: survey.id).destroy_all
  survey.destroy
end

def clear_survey_notifications
  survey = Survey.find_by(name: "generated survey")
  return unless survey

  assignment = SurveyAssignment.where(survey_id: survey.id)
  return unless assignment

  assignment.destroy_all
end
