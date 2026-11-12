# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/course_application_default_questions"

describe CourseApplicationDefaultQuestions do
  let(:config) { YAML.safe_load_file(described_class::CONFIG_PATH) }

  describe 'the config file' do
    it 'gives every question a unique, negative id and a unique key' do
      ids = config['questions'].map { |q| q['id'] }
      keys = config['questions'].map { |q| q['key'] }
      expect(ids).to all(be_a(Integer).and(be_negative))
      expect(ids.uniq.size).to eq(ids.size)
      expect(keys.uniq.size).to eq(keys.size)
    end

    it 'conditions questions only on an option of a question asked earlier' do
      config['questions'].each_with_index do |q, index|
        next unless q['shown_if']
        parent = config['questions'].first(index).find { |p| p['key'] == q['shown_if']['question'] }
        expect(parent).to be_present, "#{q['key']}: no earlier #{q['shown_if']['question']}"
        expect(parent['options']).to include(q['shown_if']['equals'])
      end
    end

    it 'names Salesforce fields as Object.Field, and maps only real options' do
      config['questions'].each do |q|
        Array(q['salesforce']).each do |field|
          expect(field).to match(/\A(Contact|Course_Contact__c)\.\w+\z/)
        end
        next unless q['salesforce_values']
        expect(q['options']).to include(*q['salesforce_values'].keys)
      end
    end

    it 'gives the length of every Salesforce field a text answer goes to' do
      lengths = config['salesforce_field_lengths']
      config['questions'].each do |q|
        next unless %w[Short Long].include?(q['type'])
        Array(q['salesforce']).each do |field|
          expect(lengths[field]).to be_a(Integer), "#{q['key']}: no length for #{field}"
        end
      end
    end

    it 'loads options as strings' do
      options = config['questions'].flat_map { |q| Array(q['options']) }
      expect(options).to all(be_a(String))
    end
  end

  describe '.group' do
    it 'is an unsaved, read-only Rapidfire group of the questions still asked' do
      group = described_class.group
      expect(group).to be_a(Rapidfire::QuestionGroup)
      expect(group).not_to be_persisted
      expect(group).to be_readonly
      expect(group.questions.map(&:id)).to eq(config['questions'].map { |q| q['id'] })
    end

    it 'builds each question from its Rapidfire class, with its rules and options' do
      pronouns = described_class.entry(:pronouns).question
      expect(pronouns).to be_a(Rapidfire::Questions::Radio)
      expect(pronouns.rules[:presence]).to eq('1')
      expect(pronouns.options).to eq(['She/her', 'He/him', 'They/them', 'Something else'])
      expect(pronouns.question_group).to equal(described_class.group)
      expect { pronouns.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it 'turns shown_if into a Rapidfire conditional on the parent question' do
      pronouns = described_class.entry(:pronouns).question
      expect(described_class.entry(:pronouns_other).question.conditionals)
        .to eq("#{pronouns.id}|=|Something_else|multi")
    end
  end

  describe 'retired questions' do
    around do |example|
      described_class.reload!
      example.run
      described_class.reload!
    end

    it 'leaves them off the form, but still resolves their answers' do
      retired = config.deep_dup
      retired['questions'].find { |q| q['key'] == 'comments' }['retired'] = true
      allow(YAML).to receive(:safe_load_file).and_call_original
      allow(YAML).to receive(:safe_load_file).with(described_class::CONFIG_PATH).and_return(retired)

      comments = described_class.entry(:comments).question
      expect(described_class.group.questions).not_to include(comments)
      expect(described_class.question(comments.id)).to equal(comments)
    end
  end

  it 'resolves only built-in ids' do
    expect(described_class.question(-1)).to be_a(Rapidfire::Question)
    expect(described_class.question(1)).to be_nil
  end
end
