# frozen_string_literal: true

require 'rails_helper'

describe 'experiments:fall_2017_cmu_experiment' do
  include_context 'rake'

  it 'calls Fall2017CmuExperiment.process_courses' do
    expect(Fall2017CmuExperiment).to receive(:process_courses)
    subject.invoke
  end
end
