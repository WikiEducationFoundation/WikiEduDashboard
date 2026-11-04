# frozen_string_literal: true

# The built-in questions on every Scholars & Scientists application form, from
# config/course_application_default_questions.yml (see the notes there). They
# are unsaved, read-only instances of the real Rapidfire classes, so the apply
# form, validation, conditionals and review pages treat them like any other
# Rapidfire question. Their answers are ordinary Rapidfire::Answer rows whose
# question_id (and answer group's question_group_id) is one of the file's
# negative ids; config/initializers/surveys.rb resolves those ids here.
#
# Anything that loads questions with SQL (joins, `where` on questions) won't
# see these.
class CourseApplicationDefaultQuestions
  CONFIG_PATH = Rails.root.join('config', 'course_application_default_questions.yml')
  GROUP_ID = -1

  # One question from the file: the Rapidfire question, its key, and where its
  # answer goes in Salesforce.
  Entry = Struct.new(:key, :question, :salesforce_fields, :salesforce_values, :retired,
                     keyword_init: true)

  class << self
    # The built-in group, with the questions still asked.
    def group
      registry[:group]
    end

    # Any built-in question by id, retired ones included, or nil.
    def question(id)
      registry[:by_id][id]&.question
    end

    def entry(key)
      registry[:by_key].fetch(key.to_s)
    end

    def entries
      registry[:by_key].values
    end

    def built_in_group_id?(id)
      id == GROUP_ID
    end

    def reload!
      @registry = nil
    end

    private

    def registry
      @registry ||= build(YAML.safe_load_file(CONFIG_PATH))
    end

    def build(config)
      group = Rapidfire::QuestionGroup.new(id: GROUP_ID, name: config.dig('group', 'name'))
      entries = config.fetch('questions').each_with_index.map do |attributes, index|
        build_entry(attributes, index + 1)
      end
      resolve_conditionals(entries, config.fetch('questions'))
      attach(group, entries)
      { group:, by_id: entries.index_by { |e| e.question.id },
        by_key: entries.index_by(&:key) }
    end

    def build_entry(attributes, position)
      klass = "Rapidfire::Questions::#{attributes.fetch('type')}".constantize
      question = klass.new(
        id: attributes.fetch('id'), question_group_id: GROUP_ID, position:,
        question_text: attributes.fetch('text'),
        answer_options: Array(attributes['options']).join("\r\n"),
        validation_rules: { presence: attributes['required'] ? '1' : '0' }
      )
      Entry.new(key: attributes.fetch('key'), question:,
                salesforce_fields: Array(attributes['salesforce']),
                salesforce_values: attributes['salesforce_values'] || {},
                retired: attributes['retired'] == true)
    end

    # `shown_if` names its parent by key; Rapidfire conditionals use the
    # parent's id, and the option with spaces as underscores, as the
    # question editor stores it.
    def resolve_conditionals(entries, config)
      by_key = entries.index_by(&:key)
      entries.zip(config).each do |entry, attributes|
        condition = attributes['shown_if']
        next unless condition
        parent = by_key.fetch(condition.fetch('question'))
        value = condition.fetch('equals').tr(' ', '_')
        entry.question.conditionals = "#{parent.question.id}|=|#{value}|multi"
      end
    end

    def attach(group, entries)
      asked = entries.reject(&:retired).map(&:question)
      group.association(:questions).target = asked
      entries.each do |entry|
        entry.question.association(:question_group).target = group
        entry.question.readonly!
      end
      group.readonly!
    end
  end
end
