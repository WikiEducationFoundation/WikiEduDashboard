require 'rails_helper'

describe TrainingProgressManager do
  let(:user)     { create(:user) }
  # first and last slide
  let(:t_module) { TrainingModule.all.first }
  let(:slides)   { [t_module.slides.first, t_module.slides.last] }
  let(:slide)    { slides.first }
  let(:last_slide_completed) { slides.first.slug }
  let(:tmu)      { create(:training_modules_users, user_id: user.try(:id), training_module_id: t_module.id, last_slide_completed: last_slide_completed, completed_at: completed_at ) }
  let(:completed_at) { nil }

  before  { tmu }
  subject { described_class.new(user, t_module, slide) }

  describe '#slide_completed?' do
    context 'tmu is nil' do
      let(:tmu) { nil }
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

    context 'tmu is nil (user has not started module yet)' do
      let(:tmu) { nil }
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
    context 'user is nil' do
      let(:user) { nil }
      it 'returns nil' do
        expect(subject.module_completed?).to be_nil
      end
    end

    context 'completed_at is nil for tmu' do
      it 'returns false' do
        expect(subject.module_completed?).to eq(false)
      end
    end

    context 'completed_at is present for tmu' do
      let(:completed_at) { Time.now }
      it 'returns true' do
        expect(subject.module_completed?).to eq(true)
      end
    end
  end

  describe '#assignment_status' do
    let(:course)   { create(:course) }
    let(:user_id)  { user.id }
    let!(:cu)      { create(:courses_user, user_id: user_id, course_id: course.id) }
    let(:week)     { create(:week, course_id: course.id) }
    let(:ids)      { [t_module.id] }
    let(:due_date) { 1.week.from_now.to_date }
    let!(:block) do
      create(:block, week_id: week.id, training_module_ids: ids, due_date: due_date)
    end

    context 'user is present, has courses, courses have this module assigned' do
      context 'block has due date' do
        it "displays training assignment text" do
          expect(subject.assignment_status).to eq(
           "Training Assignment (due " + 1.week.from_now.to_date.strftime("%m/%d/%Y") + ")"
          )
        end
      end

      context 'block has no due date' do
        let(:due_date) { nil }
        it "displays training assignment text with no date" do
          expect(subject.assignment_status).to eq("Training Assignment (no due date)")
        end
      end
    end

    context 'user is present, has courses, no courses have blocks with this module' do
      let(:ids) { [] }
      it "returns nil" do
        expect(subject.assignment_status).to be_nil
      end
    end

    context 'user is nil' do
      let(:user_id) { nil }
      it 'returns nil' do
        expect(subject.assignment_status).to be_nil
      end
    end

    context 'user has no courses' do
      before { user.courses_users.destroy_all }
      it 'returns nil' do
        expect(subject.assignment_status).to be_nil
      end
    end
  end

  describe '#module_progress' do
    context 'user is nil' do
      let(:user) { nil }
      it 'returns nil' do
        expect(subject.module_progress).to be_nil
      end
    end

    context 'completed' do
      let(:completed_at) { Time.now }
      it 'returns "completed"' do
        expect(subject.module_progress).to eq('Complete')
      end
    end

    context 'not started' do
      let(:completed_at) { nil }
      let(:last_slide_completed) { nil }
      it 'returns nil' do
        expect(subject.module_progress).to be_nil
      end
    end

    context 'partial completion' do
      context 'round down' do
        let(:completed_at) { nil }
        context '12 of 35' do
          # module has 35 slides
          let(:last_slide_completed) { t_module.slides[11].slug }
          it 'returns 34%' do
            expect(subject.module_progress).to eq('34% Complete')
          end
        end
      end

      context 'round up' do
        let(:completed_at) { nil }
        context '23 of 35' do
          # module has 35 slides
          let(:last_slide_completed) { t_module.slides[22].slug }
          it 'returns 66%' do
            expect(subject.module_progress).to eq('66% Complete')
          end
        end
      end
    end
  end
end
