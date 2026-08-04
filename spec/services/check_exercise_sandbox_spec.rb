# frozen_string_literal: true

require 'rails_helper'

describe CheckExerciseSandbox do
  before { TrainingModule.load_all }

  let(:course) { create(:course) }
  let(:user) { create(:user, username: 'Ragesock') }
  let(:training_module) { TrainingModule.find_by(slug: module_slug) }
  let(:training_module_user) do
    TrainingModulesUsers.create(user:, training_module_id: training_module.id)
  end
  let(:subject) { described_class.new(training_module_user:, course:) }

  context 'when the exercise expects no page at all' do
    let(:module_slug) { 'copyedit-exercise' }

    it 'is eligible' do
      expect(subject).to be_eligible
    end

    it 'does not query the wiki' do
      expect(WikiApi).not_to receive(:new)
      subject
    end
  end

  context 'when the exercise expects a page under the userpage' do
    let(:module_slug) { 'choose-topic-exercise' }

    context 'and the page exists' do
      let(:user) { create(:user, username: 'Kmblim') }

      it 'is eligible' do
        VCR.use_cassette 'exercise_sandbox/user_sandbox' do
          expect(subject).to be_eligible
        end
      end
    end

    context 'and the page does not exist' do
      it 'is not eligible' do
        VCR.use_cassette 'exercise_sandbox/user_sandbox' do
          expect(subject).not_to be_eligible
        end
      end

      it 'reports the expected page' do
        VCR.use_cassette 'exercise_sandbox/user_sandbox' do
          expect(subject.missing_pages).to eq(['User:Ragesock/Choose_an_Article'])
        end
      end
    end
  end

  context 'when the exercise expects a bibliography for an assigned article' do
    let(:module_slug) { 'bibliography-exercise' }
    # This sandbox exists, but it has no /Bibliography subpage.
    let(:sandbox_url) { 'https://en.wikipedia.org/wiki/User:Ragesock/student_sandbox' }
    # This sandbox does not exist, but it does have a /Bibliography subpage.
    let(:sandbox_url_with_bibliography) do
      'https://en.wikipedia.org/wiki/User:Ragesock/student_sandbox_empty'
    end
    let(:assignment_params) do
      { course:, user:, wiki_id: 1, role: Assignment::Roles::ASSIGNED_ROLE }
    end

    context 'and the student has no assigned article' do
      it 'is not eligible' do
        expect(subject).not_to be_eligible
      end

      it 'is awaiting an article assignment' do
        expect(subject).to be_awaiting_article_assignment
      end

      it 'does not query the wiki' do
        expect(WikiApi).not_to receive(:new)
        subject
      end
    end

    context 'and the student is only reviewing an article' do
      before do
        create(:assignment, **assignment_params.merge(
          role: Assignment::Roles::REVIEWING_ROLE, sandbox_url:
        ))
      end

      it 'is awaiting an article assignment' do
        expect(subject).to be_awaiting_article_assignment
      end
    end

    context 'and the bibliography page does not exist' do
      before { create(:assignment, **assignment_params.merge(sandbox_url:)) }

      it 'is not eligible' do
        VCR.use_cassette 'exercise_sandbox/assignment_sandbox' do
          expect(subject).not_to be_eligible
        end
      end

      it 'reports the expected page' do
        VCR.use_cassette 'exercise_sandbox/assignment_sandbox' do
          expect(subject.missing_pages)
            .to eq(['User:Ragesock/student_sandbox/Bibliography'])
        end
      end
    end

    context 'and the bibliography page exists' do
      before do
        create(:assignment, **assignment_params.merge(
          sandbox_url: sandbox_url_with_bibliography
        ))
      end

      it 'is eligible' do
        VCR.use_cassette 'exercise_sandbox/assignment_sandbox' do
          expect(subject).to be_eligible
        end
      end
    end

    context 'and only one of several assigned articles has a bibliography page' do
      before do
        create(:assignment, **assignment_params.merge(sandbox_url:))
        create(:assignment, **assignment_params.merge(
          article_title: 'Selenocysteine', sandbox_url: sandbox_url_with_bibliography
        ))
      end

      it 'is eligible' do
        VCR.use_cassette 'exercise_sandbox/assignment_sandbox' do
          expect(subject).to be_eligible
        end
      end

      it 'checks both pages in a single request' do
        expect_any_instance_of(WikiApi).to receive(:get_page_info)
          .with(['User:Ragesock/student_sandbox/Bibliography',
                 'User:Ragesock/student_sandbox_empty/Bibliography'])
          .and_return(nil)
        subject
      end
    end
  end

  context 'when the exercise expects an outline for an assigned article' do
    let(:module_slug) { 'outline-exercise' }

    before do
      create(:assignment, course:, user:, wiki_id: 1,
                          role: Assignment::Roles::ASSIGNED_ROLE,
                          sandbox_url: 'https://en.wikipedia.org/wiki/User:Ragesock/student_sandbox')
    end

    it 'reports the expected page when it does not exist' do
      VCR.use_cassette 'exercise_sandbox/assignment_sandbox' do
        expect(subject.missing_pages).to eq(['User:Ragesock/student_sandbox/Outline'])
      end
    end
  end

  context 'when the wiki cannot be reached' do
    let(:module_slug) { 'choose-topic-exercise' }

    before { allow_any_instance_of(WikiApi).to receive(:get_page_info).and_return(nil) }

    it 'is eligible, rather than blocking the student' do
      expect(subject).to be_eligible
    end
  end
end
