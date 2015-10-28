require 'rails_helper'

describe TrainingProgressManager do
  let(:user)     { create(:user) }
  # first and last slide
  let(:slides)   { [OpenStruct.new(slug: 'neutral-point-of-view'), OpenStruct.new(slug: 'five-pillars-quiz-1')] }
  let(:t_module) { TrainingModule.all.first }
  let(:slide)    { slides.first }
  let(:last_slide_completed) { slides.first.slug }
  let!(:utm)      { create(:training_modules_users, user_id: user.id, training_module_id: t_module.id, last_slide_completed: last_slide_completed) }

  subject { described_class.new(user, t_module, slide) }

  describe '#slide_completed?' do
    context 'last slide completed is nil' do
      let(:last_slide_completed) { nil }
      it 'returns false' do
        expect(subject.slide_completed?).to eq(false)
      end
    end

    context 'last slide completed is first slide' do
      it 'returns true' do
        expect(subject.slide_completed?).to eq(true)
      end
    end

    context 'last slide completed is first slide; slide in question is last slide' do
      let(:last_slide_completed) { slides.first.slug }
      let(:slide) { slides.last }
      it 'returns false' do
        expect(subject.slide_completed?).to eq(false)
      end
    end
  end

  describe '#slide_enabled?' do
    context 'slide is first slide; no slides viewed for this module' do
      let(:last_slide_completed) { nil }
      it 'returns true' do
        expect(subject.slide_enabled?).to eq(true)
      end
    end

    context 'slide has been seen' do
      let(:last_slide_completed) { slides.first.slug }
      let(:slide) { slides.first }
      it 'returns true' do
        expect(subject.slide_enabled?).to eq(true)
      end
    end

    context 'slide has not been seen' do
      let(:last_slide_completed) { slides.first.slug }
      let(:slide) { slides.last }
      it 'returns false' do
        expect(subject.slide_enabled?).to eq(false)
      end
    end
  end
end
