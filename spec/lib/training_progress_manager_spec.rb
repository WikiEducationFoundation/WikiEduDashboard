require 'rails_helper'

describe TrainingProgressManager do
  let(:user)     { create(:user) }
  # first and last slide
  let(:t_module) { TrainingModule.all.first }
  let(:slides)   { [t_module.slides.first, t_module.slides.last] }
  let(:slide)    { slides.first }
  let(:last_slide_completed) { slides.first.slug }
  let(:utm)      { create(:training_modules_users, user_id: user.try(:id), training_module_id: t_module.id, last_slide_completed: last_slide_completed, completed_at: completed_at ) }
  let(:completed_at) { nil }

  before  { utm }
  subject { described_class.new(user, t_module, slide) }

  describe '#slide_completed?' do
    context 'utm is nil' do
      let(:utm) { nil }
      it 'returns false' do
        expect(subject.slide_completed?).to eq(false)
      end
    end

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
    context 'user (current_user) is nil (if user is not signed in, all of training is available' do
      let(:user) { nil }
      it 'returns true' do
        expect(subject.slide_enabled?).to eq(true)
      end
    end

    context 'utm is nil (user has not started module yet)' do
      let(:utm) { nil }
      context 'slide is first slide' do
        it 'returns true' do
          expect(subject.slide_enabled?).to eq(true)
        end
      end
      context 'slide is not first slide' do
        let(:slide) { slides.last }
        it 'returns false' do
          expect(subject.slide_enabled?).to eq(false)
        end
      end
    end

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

  describe '#module_completed?' do
    context 'completed_at is nil for utm' do
      it 'returns false' do
        expect(subject.module_completed?).to eq(false)
      end
    end

    context 'completed_at is present for utm' do
      let(:completed_at) { Time.now }
      it 'returns true' do
        expect(subject.module_completed?).to eq(true)
      end
    end
  end
end
