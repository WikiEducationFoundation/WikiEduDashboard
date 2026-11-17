# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/rapidfire_conditionals"

describe RapidfireConditionals do
  def question(id, conditionals = nil)
    Rapidfire::Question.new(id:, conditionals:)
  end

  def visible?(target, questions, answers)
    described_class.new(questions, answers).visible?(target)
  end

  let(:parent) { question(1) }

  it 'shows a question with no conditional' do
    expect(visible?(parent, [parent], {})).to be true
  end

  describe 'an answer conditional' do
    # As the survey admin stores it: spaces as underscores.
    let(:child) { question(2, '1|=|Something_else|multi') }

    it 'is shown when the parent has the matching answer' do
      expect(visible?(child, [parent, child], { '1' => 'Something else' })).to be true
    end

    it 'is hidden for any other answer' do
      expect(visible?(child, [parent, child], { '1' => 'She/her' })).to be false
    end

    it 'is hidden when the parent is unanswered' do
      expect(visible?(child, [parent, child], {})).to be false
    end

    it 'is shown when any checked option of a checkbox parent matches' do
      expect(visible?(child, [parent, child], { '1' => ['White', 'Something else'] })).to be true
    end

    it 'matches a value whose quotes the admin UI stored as entities' do
      quoted = question(2, "1|=|I&#39;m_not_sure|multi")
      expect(visible?(quoted, [parent, quoted], { '1' => "I'm not sure" })).to be true
    end
  end

  describe 'a presence conditional' do
    let(:child) { question(2, '1|*presence') }

    it 'is shown once the parent has any answer' do
      expect(visible?(child, [parent, child], { '1' => 'Anything' })).to be true
      expect(visible?(child, [parent, child], { '1' => '  ' })).to be false
    end
  end

  describe 'a comparison conditional' do
    let(:child) { question(2, '1|>=|18') }

    it 'compares the parent answer as a number' do
      expect(visible?(child, [parent, child], { '1' => '21' })).to be true
      expect(visible?(child, [parent, child], { '1' => '12' })).to be false
      expect(visible?(child, [parent, child], { '1' => 'eighteen' })).to be false
    end
  end

  it 'hides a question whose parent is hidden' do
    child = question(2, '1|=|Yes|multi')
    grandchild = question(3, '2|*presence')
    answers = { '1' => 'No', '2' => 'An answer left over from before' }
    expect(visible?(grandchild, [parent, child, grandchild], answers)).to be false
  end

  it 'hides a question whose parent is not among the questions' do
    orphan = question(2, '99|*presence')
    expect(visible?(orphan, [parent, orphan], { '99' => 'Yes' })).to be false
  end
end
