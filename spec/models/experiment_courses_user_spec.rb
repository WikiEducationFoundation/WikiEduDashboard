# frozen_string_literal: true

require 'rails_helper'

describe ExperimentCoursesUser do
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:courses_user) do
    create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  it 'persists an opt-in status tied to a courses_user, user and course' do
    record = described_class.create!(experiment_slug: 'fall_2026_research',
                                     courses_user:, status: :opted_in)
    expect(record.opted_in?).to be true
    expect(record.user).to eq(user)
    expect(record.course).to eq(course)
  end

  it 'is unique per experiment and courses_user' do
    described_class.create!(experiment_slug: 'fall_2026_research',
                            courses_user:, status: :opted_in)
    duplicate = described_class.new(experiment_slug: 'fall_2026_research',
                                    courses_user:, status: :opted_out)
    expect(duplicate).not_to be_valid
  end

  it 'allows the same courses_user in a different experiment' do
    described_class.create!(experiment_slug: 'fall_2026_research',
                            courses_user:, status: :opted_in)
    other = described_class.new(experiment_slug: 'other_experiment',
                                courses_user:, status: :opted_in)
    expect(other).to be_valid
  end

  it 'is removed when its courses_user is destroyed' do
    record = described_class.create!(experiment_slug: 'fall_2026_research',
                                     courses_user:, status: :opted_in)
    courses_user.destroy
    expect(described_class.exists?(record.id)).to be false
  end
end
