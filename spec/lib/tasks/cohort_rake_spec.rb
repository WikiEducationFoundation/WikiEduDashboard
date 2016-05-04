require 'rails_helper'

describe 'cohort:add_cohorts' do
  include_context 'rake'

  it 'calls Cohort.initialize_cohorts' do
    expect(Cohort).to receive(:initialize_cohorts)
    subject.invoke
  end
end
