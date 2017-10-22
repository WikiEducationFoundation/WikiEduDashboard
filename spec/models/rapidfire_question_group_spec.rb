# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe Rapidfire::QuestionGroup do
  describe 'association' do
    it { should have_many(:question_group_conditionals) }
    it { should have_many(:campaigns).through(:question_group_conditionals) }
  end
end
