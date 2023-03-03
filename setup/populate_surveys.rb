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
  Course.last(n_courses).each do |course|
    random_users = User.where(email: "generated user").order("RAND()").limit(20)
    random_users.each do |random_user|
      courses_users << {
        course_id: course.id,
        user_id: random_user.id,
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
  clear_rapidfire_question_groups
  clear_survey
  clear_survey_notifications

  2.times do |i|
    Rapidfire::QuestionGroup.create(
      name: "generated group",
      tags: ""
    )
  end
  
  question_groups = Rapidfire::QuestionGroup.last(2).to_a

  to_create = []
  survey_notifications = []
  
  n_questions = ENV['questions'] || 100
  j = 0
  1..n_questions.to_i.times do |i|
    if j == question_groups.length
      j = 0
    end
    to_create << {
      question_group_id: question_groups[j].id, 
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
    j += 1
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
  
  question_groups.each_with_index do |question_group, i|
    SurveysQuestionGroup.create(
      survey_id: generated_survey.id,
      rapidfire_question_group_id: question_group.id,
      position: i + 1
    )
  end

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
  question_groups = Rapidfire::QuestionGroup.where(name: "generated group").to_a

  to_create = []
  i = 0
  n_responses = ENV['responses'] || 200
  1..n_responses.to_i.times do |round|
    if i == question_groups.length
      i = 0
    end
    question_group_id = question_groups[i].id
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
    i += 1
  end
  Rapidfire::Answer.insert_all(to_create)
end

def clear_survey_answers_for_group question_group
  return unless question_group
  to_delete = []
  Rapidfire::AnswerGroup.where(
    question_group_id: question_group.id,
  ).each do |answer_group|
    Rapidfire::Answer.where(
      answer_group_id: answer_group.id
    ).each do |answer|
      to_delete << answer
    end
  end
  Rapidfire::Answer.delete(to_delete)
end

def clear_survey_questions_for_group question_group
  return unless question_group
  Rapidfire::Question.where(
    question_group_id: question_group.id,
  ).destroy_all
end

def clear_survey_answers 
  question_groups = Rapidfire::QuestionGroup.where(name: "generated group")

  question_groups.each do |question_group|
    clear_survey_answers_for_group question_group
  end
end

def clear_survey_questions
  question_groups = Rapidfire::QuestionGroup.where(name: "generated group")

  question_groups.each do |question_group|
    clear_survey_questions_for_group question_group
  end
end

def clear_rapidfire_question_groups
  Rapidfire::QuestionGroup.where(name: "generated group").delete_all
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
