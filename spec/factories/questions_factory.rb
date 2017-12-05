# frozen_string_literal: true

FactoryBot.define do
  factory :question do
    validation_rules = {
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

    question_group  { FactoryBot.create(:question_group) }
    question_text   'Sample Question'

    factory :q_checkbox, class: 'Rapidfire::Questions::Checkbox' do
      answer_options "hindi\r\ntelugu\r\nkannada\r\n"
      validation_rules validation_rules
      question_text 'Checkbox Question'
    end

    factory :q_date, class: 'Rapidfire::Questions::Date' do
      validation_rules validation_rules
      question_text 'Date Question'
    end

    factory :q_long, class: 'Rapidfire::Questions::Long' do
      validation_rules validation_rules
      question_text 'Long Text Question'
    end

    factory :q_numeric, class: 'Rapidfire::Questions::Numeric' do
      validation_rules validation_rules
      question_text   'Numeric Question'
    end

    factory :q_radio, class: 'Rapidfire::Questions::Radio' do
      answer_options  "male\r\nfemale\r\n"
      validation_rules validation_rules
      question_text   'Radio Question'
    end

    factory :q_select, class: 'Rapidfire::Questions::Select' do
      answer_options  "mac\r\nwindows\r\n"
      validation_rules validation_rules
      question_text 'Select Question'
    end

    factory :q_short, class: 'Rapidfire::Questions::Short' do
      validation_rules validation_rules
      question_text 'Short Text Question'
    end

    rangeinput_params = validation_rules.merge!(range_minimum: '0',
                                                range_maximum: '100',
                                                range_increment: '5',
                                                range_divisions: '',
                                                range_format: '%')
    factory :q_rangeinput, class: 'Rapidfire::Questions::RangeInput' do
      validation_rules rangeinput_params
      question_text 'RangeInput Question'
    end
  end
end
