require 'spec_helper'

describe Rapidfire::AnswerGroup do
  describe "Associations" do
    it { is_expected.to belong_to(:question_group) }
    it { is_expected.to belong_to(:user)    }
    it { is_expected.to have_many(:answers) }
  end
end
