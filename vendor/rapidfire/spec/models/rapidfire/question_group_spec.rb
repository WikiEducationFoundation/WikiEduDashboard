require 'spec_helper'

describe Rapidfire::QuestionGroup do
  describe "Validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "Associations" do
    it { is_expected.to have_many(:questions) }
  end
end
