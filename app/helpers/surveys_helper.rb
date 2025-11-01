# frozen_string_literal: true

# Rubocop now wants us to remove instance methods from helpers. This is a good idea
# but will require a bit of refactoring. Find other instances of this disabling
# and fix all at once.
# rubocop:disable Rails/HelperInstanceVariable

module SurveysHelper
  include CourseHelper

  def survey_course_title
    if @course.nil? || !Features.wiki_ed?
      'Survey'
    else
      "Survey for #{@course.title} (#{@course.term})"
    end
  end

  def render_matrix_answer_labels(answer)
    render partial: 'rapidfire/answers/matrix_answer_labels',
           locals: { answer:, course: @course }
  end

  def survey_preview_url(survey)
    "#{survey_url(survey)}?preview"
  end

  # Generate preview links for courses that match question group conditions
  def survey_preview_links(survey)
    tags_with_groups = collect_tags_from_question_groups(survey.rapidfire_question_groups)
    links = generate_preview_links_for_tags(survey, tags_with_groups)
    add_generic_preview_if_needed(survey, links) if links.empty?
    links
  end

  def question_answer_field_name(form, multiple)
    name = "answer_group[#{form.object.question_id}][answer_text]"
    if multiple
      name + '[]'
    else
      name
    end
  end

  def survey_select(f, answer, course)
    multiple = answer.question.multiple
    field_name = question_answer_field_name(f, multiple)
    options = answer_options(answer, course)
              .collect { |o| o.is_a?(Array) ? [o[1].tr('_', ' ').to_s, o[0]] : o }
    return content_tag :div, 'remove me', data: { remove_me: true } if options.empty?
    select_tag(field_name, options_for_select(options),
               include_blank: multiple ? 'Select all that apply' : 'Select an option',
               required: required_question?(answer),
               multiple:)
  end

  def answer_options(answer, course)
    question = answer.question
    if !question.options.empty?
      question.options.collect { |q| [strip_tags(q), q, q] }
    elsif !course.nil?
      course_answer_options(question.course_data_type, course)
    end
  end

  def course_answer_options(type, course)
    case type
    when 'Students'
      course_student_choices(course)
    when 'Articles'
      course_article_choices(course)
    when 'WikiEdu Staff'
      course_wikiedu_staff_choices(course)
    end
  end

  def can_administer?
    current_user&.admin?
  end

  def required_question?(answer)
    answer.question.validation_rules[:presence].to_i == 1
  end

  def question_is_grouped?(answer)
    return false if answer.nil? || answer.question.nil?
    answer.question.validation_rules[:grouped].to_i == 1
  end

  def grouped_question(answer)
    answer.question.validation_rules[:grouped_question]
  end

  # rubocop:disable Metrics/MethodLength,Lint/MissingCopEnableDirective
  def question_group_locals(surveys_question_group, index, total, is_results_view:)
    @question_group = surveys_question_group.rapidfire_question_group
    @answer_group_builder = Rapidfire::AnswerGroupBuilder.new(params: {},
                                                              user: current_user,
                                                              question_group: @question_group)

    @questions = Rapidfire::Question.where(question_group_id: @question_group.id)

    @id_to_question = {}
    @questions.each do |question|
      @id_to_question[question.id] = question
    end

    enrich_answers_with_question

    if is_results_view
      load_and_prepare_question_answers
      load_answer_group_and_user
    end

    return { question_group: @question_group,
      answer_group_builder: @answer_group_builder,
      question_group_index: index,
      surveys_question_group:,
      total:,
      results: is_results_view }
  end

  # Eager load answers with their groups, index them by question ID, and count per question.
  def load_and_prepare_question_answers
    # Used in QuestionResultsHelper#question_results_data via view: _question_group.html.haml
    @rapidfire_answers_by_question_id = Hash.new { |h, k| h[k] = [] }
    @question_answers_count = Hash.new(0) # Used in view: _question_results.html.haml
    @all_rapidfire_answers = []

    Rapidfire::Answer.includes(:answer_group)
                     .where(question_id: @id_to_question.keys)
                     .each do |answer|
      @rapidfire_answers_by_question_id[answer.question_id] << answer
      @question_answers_count[answer.question_id] += 1
      @all_rapidfire_answers << answer
    end
  end

  # Builds cache of unique answer groups and their associated users to avoid N+1 queries
  def load_answer_group_and_user
    seen_group_ids = Set.new
    user_ids = Set.new
    rapidfire_answer_groups = []

    @all_rapidfire_answers.each do |answer|
      group = answer.answer_group
      next if seen_group_ids.include?(group.id)

      seen_group_ids.add(group.id)
      rapidfire_answer_groups << group
      user_ids.add(group.user_id) if group.user_id
    end

    # Used in QuestionResultsHelper#question_results_data via view: _question_group.html.haml
    @rapidfire_answer_groups_by_id = rapidfire_answer_groups.index_by(&:id)

    # Used in QuestionResultsHelper#question_results_data via view: _question_group.html.haml
    @users_by_id = User.where(id: user_ids.to_a).select(:id, :username).index_by(&:id)
  end

  def enrich_answers_with_question
    @answer_group_builder.answers.each do |answer|
      question = @id_to_question[answer.question_id]
      answer.question = question
    end
  end

  # Attaches course data to users via dynamic method for easy access to course campaigns and tags
  def user_survey_courses
    # Step 1: Fetch the first completed survey notification for each user
    # that is associated with the given survey.
    notifications_by_user = SurveyNotification
                            .joins(:courses_user, :survey_assignment)
                            .where(
                              courses_users: { user_id: @users_by_id.keys },
                              completed: true,
                              survey_assignments: { survey_id: @survey.id }
                            )
                            .select(
                              'survey_notifications.id',
                              'survey_notifications.course_id',
                              'courses_users.user_id AS user_id'
                            )
                            .order('survey_notifications.id')
                            .group_by(&:user_id)
                            .transform_values(&:first)

    # Step 2: Collect all unique course IDs from these notifications.
    course_ids = notifications_by_user.values.map(&:course_id).uniq

    # # Step 3: Eager-load campaigns and tags for all relevant courses,
    courses_by_id = Course.where(id: course_ids)
                          .select(:id, :title)
                          .includes(:campaigns, :tags)
                          .index_by(&:id)

    # Step 4: Attach the corresponding course to each user using a dynamic method.
    # This allows easy access to `user.survey_course` elsewhere in the app.
    # Currently it's being used by QuestionResultsHelper#build_question_answer_data
    notifications_by_user.each do |user_id, notification|
      user = @users_by_id[user_id]
      course = courses_by_id[notification.course_id]
      # Dynamically define a method to access course on user
      user.define_singleton_method(:survey_course) { course }
    end
  end

  def question_conditional_string(question)
    return '' if question.nil?
    return '' unless valid_conditional_question?(question.conditionals)
    return question.conditionals
  end

  def course_data?(question_form)
    question_form.course_data_type.present?
  end

  def question_form_has_follow_up_question(question_form)
    question_form.follow_up_question_text.present?
  end

  def conditional_attribute(answer)
    return unless answer.question.conditionals?
    strip_tags(answer.question.conditionals).tr(' ', '_').tr("'", "\\'")
  end

  def numeric_min(answer)
    rule = answer.question.rules[:greater_than_or_equal_to]
    rule.empty? ? '0' : rule
  end

  def numeric_max(answer)
    rule = answer.question.rules[:less_than_or_equal_to]
    rule.empty? ? '999999999' : rule
  end

  def valid_conditional_question?(conditional_string)
    return false if conditional_string.nil?
    question_id = conditional_string.split('|').first.to_i
    Rapidfire::Question.exists?(question_id)
  end

  private

  # Collect all unique tags from question groups and map them to group names
  def collect_tags_from_question_groups(question_groups)
    tags_with_groups = {}
    question_groups.each do |qg|
      next if qg.tags.blank?

      tag_list = qg.tags.split(',').map(&:strip)
      tag_list.each do |tag|
        tags_with_groups[tag] ||= []
        tags_with_groups[tag] << qg.name
      end
    end
    tags_with_groups
  end

  # Generate preview links for each tag by finding recent courses with that tag
  def generate_preview_links_for_tags(survey, tags_with_groups)
    links = []
    tags_with_groups.each do |tag, group_names|
      course = find_recent_course_with_tag(tag)
      next unless course

      links << build_preview_link(survey, tag, course, group_names)
    end
    links
  end

  # Find a recent course (within last 6 months) with the given tag
  def find_recent_course_with_tag(tag)
    Course.joins(:tags)
          .where(tags: { tag: })
          .where('courses.end >= ?', 6.months.ago)
          .order('courses.end DESC')
          .first
  end

  # Build a preview link object with all necessary details
  def build_preview_link(survey, tag, course, group_names)
    {
      url: "#{survey_url(survey)}?preview&course_slug=#{course.slug}",
      label: "Preview with '#{tag}' tag",
      course_title: course.title,
      question_groups: group_names.uniq.join(', ')
    }
  end

  # Add a generic preview link if no tag-specific links were generated
  def add_generic_preview_if_needed(survey, links)
    # Try to find a default course with edited articles
    default_course = find_default_preview_course

    preview_link = if default_course
                     {
                       url: "#{survey_url(survey)}?preview&course_slug=#{default_course.slug}",
                       label: 'Preview (default course)',
                       course_title: default_course.title,
                       question_groups: 'All'
                     }
                   else
                     # Fallback to manual selection if no suitable course found
                     {
                       url: survey_preview_url(survey),
                       label: 'Preview (select course)',
                       course_title: nil,
                       question_groups: 'All'
                     }
                   end
    links << preview_link
  end

  # Find a recent course with edited articles for use as a default preview
  def find_default_preview_course
    # Try to find a recent course with articles (last 6 months)
    course = Course.joins(:articles_courses)
                   .where('courses.end >= ?', 6.months.ago)
                   .distinct
                   .order('courses.end DESC')
                   .first

    # Fallback: any course with articles (no time limit)
    course ||= Course.joins(:articles_courses)
                     .distinct
                     .order('courses.end DESC')
                     .first

    # Last resort: just get any recent course
    course ||= Course.where('courses.end >= ?', 6.months.ago)
                     .order('courses.end DESC')
                     .first

    # Absolute fallback: any course at all
    course ||= Course.order('courses.end DESC').first

    course
  end

  def survey_notification_id(notification)
    return nil if notification == false || notification.nil?
    return notification.id
  end

  def survey_class_for_path(req, path)
    current_path_segments = req.path.split('/').reject(&:blank?)
    active_path = path.split('/').reject(&:blank?).last
    current_path_segments.include?(active_path) ? 'active' : nil
  end

  ######################
  # Setting the course #
  ######################

  # If at all possible, find the course to associate with this survey.
  # Setting a course is necessary for conditional features of surveys — question
  # groups that only apply to certain campaigns, or for courses with certain tags
  # — to work.
  # First go based on slug. Next, go based on notification.
  # For preview mode, fall back to the course_select dropdown.
  # For a real survey, fall back to the user's latest course.
  def set_course
    @course = find_course_by_slug(params[:course_slug]) if course_slug?
    @course ||= @notification.course if @notification.instance_of?(SurveyNotification)
    return if @course
    if preview_mode?
      set_course_via_select
    else
      fall_back_to_last_course_for_user
    end
  end

  def set_course_via_select
    @courses = Course.all
    render 'course_select'
  end

  def fall_back_to_last_course_for_user
    @course = current_user.courses.last
  end

  def preview_mode?
    params.key?(:preview)
  end

  ######################################
  # Methods called only from this file #
  ######################################

  def course_student_choices(course)
    students = course.courses_users.where(role: CoursesUsers::Roles::STUDENT_ROLE)
    students.collect { |cu| [cu.user.id, cu.user.username, contribution_link(cu).to_s] }
  end

  def course_article_choices(course)
    course.articles.collect do |a|
      [a.url, a.title, "<a href='#{a.url}' target='_blank'>#{a.title}</a>"]
    end
  end

  def course_wikiedu_staff_choices(course)
    staff = course.courses_users.where(role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
    staff.collect { |cu| [cu.user.id, cu.user.username, contribution_link(cu).to_s] }
  end

  def course_slug?
    params.key?(:course_slug)
  end
end

# rubocop:enable Rails/HelperInstanceVariable
