# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe Rapidfire::QuestionGroup do
  describe 'association' do
    it { is_expected.to have_many(:question_group_conditionals) }
    it { is_expected.to have_many(:campaigns).through(:question_group_conditionals) }
  end
end
