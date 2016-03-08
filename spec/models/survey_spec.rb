require 'rails_helper'

RSpec.describe Survey, type: :model do
  it { should have_many :rapidfire_question_groups }
end

RSpec.describe Rapidfire::QuestionGroup, type: :model do
  it { should belong_to :survey }
end
