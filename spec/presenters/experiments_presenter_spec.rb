# frozen_string_literal: true

require 'rails_helper'

describe ExperimentsPresenter do
  let(:subject) { described_class.new(course) }
  let(:course) { create(:course, flags:) }

  describe '#experiment' do
    context 'when the course is not in an experiment' do
      let(:flags) { {} }

      it 'retuns nil' do
        expect(subject.experiment).to be_nil
      end
    end

    context 'when the course is in an active experiment' do
      let(:flags) { { spring_2018_cmu_experiment: 'email_sent' } }

      it 'retuns the experiment class' do
        expect(subject.experiment).to eq(Spring2018CmuExperiment)
      end
    end
  end

  describe '#notification' do
    context 'when the course is in an active experiment' do
      let(:flags) do
        {
          spring_2018_cmu_experiment: 'email_sent',
          spring_2018_cmu_experiment_email_code: 'secret'
        }
      end

      it 'includes an opt_in_link with the email code' do
        expect(subject.notification[:opt_in_link]).to match(/secret/)
      end
    end
  end
end
