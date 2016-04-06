require 'active_support'
require 'rapidfire'

Rails.application.config.to_prepare do

  Rapidfire::QuestionGroup.class_eval do
    has_many :question_group_conditionals, foreign_key: 'rapidfire_question_group_id'
    has_many :cohorts, through: :question_group_conditionals
    has_and_belongs_to_many :surveys, join_table: 'surveys_question_groups', foreign_key: 'rapidfire_question_group_id'
  end

  Rapidfire::QuestionGroupsController.class_eval do
    before_action :set_tags, only: [:new, :edit]

    def new
      @question_group = Rapidfire::QuestionGroup.new
      @question_group_tags = []
    end

    def edit
      @question_group = Rapidfire::QuestionGroup.find(params[:id])
      @question_group_tags = @question_group.tags.nil? ? [] : @question_group.tags.split(',')
    end

    private

    def question_group_params
      join_tags
      params.require(:question_group).permit(:name, :tags, cohort_ids: [])
    end

    def join_tags
      tags = params[:question_group][:tags]
      params[:question_group][:tags] = tags.nil? ? "" : tags.join(',')
    end

    def set_tags
      @available_tags = Tag.uniq.pluck(:tag)
    end
  end

  Rapidfire::Question.class_eval do

    scope :course_data_questions, ->{where("course_data_type <> ''")}
    def self.for_conditionals
      where("conditionals IS NULL OR conditionals = ''")
    end
  end

  Rapidfire::ApplicationController.class_eval do
    layout 'surveys'
  end

  Rapidfire::AnswerGroupsController.class_eval do
    include SurveysHelper
    before_action :set_course_if_course_questions, only: [:new]
  end

  Rapidfire::QuestionForm.class_eval do

    COURSE_DATA_ANSWER_TYPES =
      [
        "Students",
        "Articles",
        "WikiEdu Staff"
      ]

    AVAILABLE_SURVEY_QUESTIONS =
      [
       Rapidfire::Questions::Checkbox,
       Rapidfire::Questions::Date,
       Rapidfire::Questions::Long,
       Rapidfire::Questions::Numeric,
       Rapidfire::Questions::Radio,
       Rapidfire::Questions::Select,
       Rapidfire::Questions::Short,
       Rapidfire::Questions::Text,
       Rapidfire::Questions::RangeInput
      ]
    SURVEY_QUESTION_TYPES = AVAILABLE_SURVEY_QUESTIONS.inject({}) do |result, question|
      question_name = question.to_s.split("::").last
      result[question_name] = question.to_s
      result
    end

    attr_accessor :question_group, :question,
      :type, :question_text, :answer_options, :answer_presence,
      :answer_minimum_length, :answer_maximum_length, :multiple,
      :answer_greater_than_or_equal_to, :answer_less_than_or_equal_to, :answer_grouped,
      :answer_grouped_question, :answer_range_minimum, :answer_range_maximum,
      :answer_range_increment, :answer_range_divisions, :answer_range_format,
      :follow_up_question_text, :conditionals, :course_data_type, :placeholder_text

    def save
      @question.new_record? ? create_question : update_question
    end

    private
    def create_question
      klass = nil
      if SURVEY_QUESTION_TYPES.values.include?(type)
        klass = type.constantize
      else
        errors.add(:type, :invalid)
        return false
      end
      @question = klass.create(to_question_params)
    end

    def to_question_params
      {
        :type => type,
        :question_group => question_group,
        :question_text  => question_text,
        :answer_options => answer_options,
        :follow_up_question_text => follow_up_question_text,
        :conditionals => conditionals,
        :multiple => multiple,
        :course_data_type => course_data_type,
        :placeholder_text => placeholder_text,
        :validation_rules => {
          :presence => !conditionals.empty? ? "0" : answer_presence,
          :grouped => answer_grouped,
          :grouped_question => answer_grouped_question,
          :minimum  => answer_minimum_length,
          :maximum  => answer_maximum_length,
          :range_minimum  => answer_range_minimum,
          :range_maximum  => answer_range_maximum,
          :range_increment    => answer_range_increment,
          :range_divisions    => answer_range_divisions,
          :range_format    => answer_range_format,
          :greater_than_or_equal_to => answer_greater_than_or_equal_to,
          :less_than_or_equal_to    => answer_less_than_or_equal_to
        }
      }
    end

    def from_question_to_attributes(question)
      self.type = question.type
      self.question_group  = question.question_group
      self.question_text   = question.question_text
      self.answer_options  = question.answer_options
      self.follow_up_question_text = question.follow_up_question_text
      self.conditionals = question.conditionals
      self.multiple = question.multiple
      self.course_data_type = question.course_data_type
      self.placeholder_text = placeholder_text
      self.answer_presence =  question.rules[:presence]
      self.answer_grouped = question.rules[:grouped]
      self.answer_grouped_question = question.rules[:grouped_question]
      self.answer_minimum_length = question.rules[:minimum]
      self.answer_maximum_length = question.rules[:maximum]
      self.answer_range_minimum = question.rules[:range_minimum]
      self.answer_range_maximum = question.rules[:range_maximum]
      self.answer_range_increment = question.rules[:range_increment]
      self.answer_range_divisions = question.rules[:range_divisions]
      self.answer_range_format = question.rules[:range_format]
      self.answer_greater_than_or_equal_to = question.rules[:greater_than_or_equal_to]
      self.answer_less_than_or_equal_to    = question.rules[:less_than_or_equal_to]
    end
  end
end
