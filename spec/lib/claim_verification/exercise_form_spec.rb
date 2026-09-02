# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/claim_verification/exercise_form"

# The exercise's shape as declared in config/claim_verification_exercise.yml.
# These specs are about the mechanics the declaration relies on — numbering,
# gating, validation — rather than the particular questions asked, so that
# refining the exercise doesn't invalidate them.
describe ClaimVerification::ExerciseForm do
  let(:form) { described_class.new }

  # A path through the exercise where the student got the source, answering
  # every required question.
  let(:complete_answers) do
    { 'source_appropriate' => 'appropriate', 'meets_rs_policy' => 'generally_reliable',
      'source_access' => 'accessed', 'verdict' => 'full_support' }
  end

  describe 'the declared steps' do
    it 'numbers the steps that show a heading, continuing the exercise count' do
      numbered = form.steps.select(&:numbered?)
      expect(numbered.map(&:number)).to eq((3..(2 + numbered.length)).to_a)
    end

    it 'gives an unnumbered step no heading' do
      unnumbered = form.steps.reject(&:numbered?)
      expect(unnumbered.map(&:heading)).to all(be_nil)
    end

    it 'composes the number into the heading rather than the copy' do
      step = form.steps.find { |candidate| candidate.id == 'find_source' }
      expect(step.heading).to eq("Step #{step.number}: Find the source")
    end

    it 'asks the source-evaluation step before the source is tracked down' do
      expect(form.steps.map(&:id).first(2)).to eq(%w[evaluate_source find_source])
    end
  end

  describe '#answer_keys' do
    it 'names every question, whatever the path through the exercise' do
      expect(form.answer_keys).to include('source_appropriate', 'source_access', 'verdict')
    end

    it 'has no duplicates, since each key stores one answer' do
      expect(form.answer_keys.uniq).to eq(form.answer_keys)
    end
  end

  describe '#applicable_questions' do
    it 'skips a gated step until its answer opens it' do
      asked = form.applicable_questions('source_access' => 'nonexistent').map(&:id)
      expect(asked).not_to include('verdict')
    end

    it 'asks a gated step once its answer opens it' do
      asked = form.applicable_questions('source_access' => 'accessed').map(&:id)
      expect(asked).to include('verdict')
    end

    it 'asks a gated question only on the branch it belongs to' do
      expect(form.applicable_questions('source_access' => 'inaccessible').map(&:id))
        .to include('source_access_notes')
    end

    it 'asks the ungated questions whatever the answers' do
      expect(form.applicable_questions({}).map(&:id)).to include('source_appropriate')
    end

    it 'holds back the closing comments until the source-access answer is in' do
      expect(form.applicable_questions({}).map(&:id)).not_to include('other_comments')
    end

    # Whichever way the student answers it — the point of gating on `true`
    # rather than a list, so a new source_access option can't leave the comments
    # behind. Derived from the declared options for the same reason.
    it 'asks the closing comments on every source-access answer' do
      source_access = form.questions.find { |question| question.id == 'source_access' }
      asked = source_access.options.map do |option|
        form.applicable_questions('source_access' => option).map(&:id)
      end
      expect(asked).to all(include('other_comments'))
    end
  end

  describe '#applicable_answers' do
    it 'keeps the answers the exercise asked for' do
      expect(form.applicable_answers(complete_answers)).to eq(complete_answers)
    end

    it 'drops answers to questions the path never asked' do
      submitted = complete_answers.merge('source_access' => 'nonexistent')
      expect(form.applicable_answers(submitted).keys).not_to include('verdict')
    end

    it 'drops keys the exercise does not ask at all' do
      submitted = complete_answers.merge('favourite_otter' => 'Sea')
      expect(form.applicable_answers(submitted).keys).not_to include('favourite_otter')
    end

    it 'drops blank answers rather than storing them' do
      submitted = complete_answers.merge('claim_location' => '')
      expect(form.applicable_answers(submitted).keys).not_to include('claim_location')
    end

    it 'accepts string or symbol keys from the client' do
      expect(form.applicable_answers(complete_answers.symbolize_keys))
        .to eq(complete_answers)
    end
  end

  describe '#errors_in' do
    it 'accepts a complete set of answers' do
      expect(form.errors_in(complete_answers)).to be_empty
    end

    it 'reports a required question left unanswered' do
      expect(form.errors_in(complete_answers.except('source_appropriate')))
        .to include(/source_appropriate is required/)
    end

    it 'reports a choice answered with something it does not offer' do
      expect(form.errors_in(complete_answers.merge('verdict' => 'sort_of')))
        .to include(/not an accepted answer for verdict/)
    end

    # An answer the exercise used to offer stays valid, so a response recorded
    # with it can still be edited and re-saved.
    it 'accepts a retired option as an answer' do
      expect(form.errors_in(complete_answers.merge('verdict' => 'mostly_supports'))).to be_empty
    end

    it 'does not require a question the path never asked' do
      answers = complete_answers.except('verdict').merge('source_access' => 'nonexistent')
      expect(form.errors_in(answers)).to be_empty
    end

    it 'never requires a free-text question' do
      expect(form.questions.select(&:required).map(&:type).uniq).to eq(['choice'])
    end
  end

  # The point of declaring the exercise in config is that refining it needs no
  # code change, so the mechanics must follow the declaration rather than the
  # questions this exercise currently happens to ask. A stand-in declaration
  # with entirely different questions proves that.
  describe 'with a different declaration' do
    let(:declaration) do
      { 'first_step_number' => 1,
        'steps' => [
          { 'id' => 'pick',
            'questions' => [{ 'id' => 'colour', 'type' => 'choice', 'required' => true,
                              'options' => %w[red blue], 'retired_options' => %w[green] }] },
          { 'id' => 'explain', 'visible_when' => { 'colour' => ['red'] },
            'questions' => [{ 'id' => 'shade', 'type' => 'text' }] },
          { 'id' => 'note', 'visible_when' => { 'colour' => true },
            'questions' => [{ 'id' => 'why', 'type' => 'text' }] }
        ] }
    end

    before { allow(described_class).to receive(:definition).and_return(declaration) }

    it 'asks whatever the declaration names' do
      expect(form.answer_keys).to eq(%w[colour shade why])
    end

    it 'numbers from the declared first step number' do
      expect(form.steps.map(&:number)).to eq([1, 2, 3])
    end

    it 'validates a choice against the options the declaration gives it' do
      expect(form.errors_in('colour' => 'purple'))
        .to include(/not an accepted answer for colour/)
    end

    it 'accepts a retired option without offering it' do
      expect(form.errors_in('colour' => 'green')).to be_empty
      expect(form.questions.first.options).not_to include('green')
      expect(form.questions.first.retired_options).to eq(['green'])
    end

    it 'gates a step on the answer the declaration names' do
      expect(form.applicable_questions('colour' => 'blue').map(&:id)).not_to include('shade')
    end

    it 'opens the gated step on the answer that satisfies it' do
      expect(form.applicable_questions('colour' => 'red').map(&:id)).to eq(%w[colour shade why])
    end

    it 'holds back a step gated on `true` while its question is unanswered' do
      expect(form.applicable_questions({}).map(&:id)).to eq(['colour'])
    end

    it 'opens a step gated on `true` on any answer, not a named one' do
      expect(form.applicable_questions('colour' => 'blue').map(&:id)).to eq(%w[colour why])
    end
  end
end
