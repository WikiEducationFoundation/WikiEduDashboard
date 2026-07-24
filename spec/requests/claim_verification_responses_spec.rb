# frozen_string_literal: true

require 'rails_helper'

# The claim-verification exercise's form submission (create, an upsert that
# also completes the exercise's training module) and the instructor-facing
# listing of everyone's responses (index).
describe 'Claim verification responses', type: :request do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course, slug: 'School/Claims_2024', home_wiki: wiki) }
  let(:student) { create(:user, username: 'Otterfan') }
  let(:claim) do
    VerificationClaim.create!(wiki:, article_title: 'Sea_otter',
                              sentence: 'Sea otters use rocks as tools.',
                              source_url: 'https://example.com/otters')
  end

  let(:accessed_answers) do
    { source_access: 'accessed', verdict: 'partial_support',
      claim_location: 'p. 44', verification_notes: 'Only the tool use is there.',
      other_comments: 'Fun exercise.' }
  end

  before do
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  describe 'POST response' do
    before { login_as student }

    it 'requires a taken claim' do
      post "/courses/#{course.slug}/verify_claim/response", params: accessed_answers
      expect(response.status).to eq(422)
    end

    context 'with a taken claim' do
      before do
        VerificationClaimAssignment.create!(user: student, course:, verification_claim: claim)
      end

      it 'stores the response for the taken claim and returns it' do
        post "/courses/#{course.slug}/verify_claim/response", params: accessed_answers
        expect(response.status).to eq(200)
        stored = VerificationClaimResponse.find_by(user: student, course:)
        expect(stored.verification_claim).to eq(claim)
        expect(stored.verdict).to eq('partial_support')
        expect(response.parsed_body['response']['claim_location']).to eq('p. 44')
      end

      it 'updates the existing response on resubmission' do
        post "/courses/#{course.slug}/verify_claim/response", params: accessed_answers
        post "/courses/#{course.slug}/verify_claim/response",
             params: accessed_answers.merge(verdict: 'contradicted')
        expect(VerificationClaimResponse.where(user: student, course:).count).to eq(1)
        expect(VerificationClaimResponse.find_by(user: student, course:).verdict)
          .to eq('contradicted')
      end

      it 'clears verify-step answers when the source was not accessed' do
        post "/courses/#{course.slug}/verify_claim/response",
             params: { source_access: 'inaccessible', verdict: 'full_support',
                       claim_location: 'p. 44', source_access_notes: 'Paywalled.',
                       other_comments: 'Frustrating.' }
        stored = VerificationClaimResponse.find_by(user: student, course:)
        expect(stored.verdict).to be_nil
        expect(stored.claim_location).to be_nil
        expect(stored.source_access_notes).to eq('Paywalled.')
        expect(stored.other_comments).to eq('Frustrating.')
      end

      it 'marks the exercise training module complete for the course' do
        # Training modules survive database cleaning, so the real module may
        # already be loaded from another suite's TrainingModule.load_all.
        exercise_module = TrainingModule.find_by(slug: 'fact-verification-exercise') ||
                          TrainingModule.create!(
                            slug: 'fact-verification-exercise', name: 'Fact verification',
                            kind: TrainingModule::Kinds::EXERCISE,
                            settings: { 'exercise_path' => 'verify_claim' }
                          )
        post "/courses/#{course.slug}/verify_claim/response", params: accessed_answers
        tmu = TrainingModulesUsers.find_by(user: student, training_module_id: exercise_module.id)
        expect(tmu.completed_at).to be_present
        expect(tmu.flags[course.id][:marked_complete]).to eq(true)
      end

      it 'rejects invalid answers without storing anything' do
        post "/courses/#{course.slug}/verify_claim/response",
             params: { source_access: 'accessed' } # missing verdict
        expect(response.status).to eq(422)
        expect(VerificationClaimResponse.find_by(user: student, course:)).to be_nil
      end

      it 'allows a further claim and response after submitting (no per-course limit)' do
        post "/courses/#{course.slug}/verify_claim/response", params: accessed_answers
        other_claim = VerificationClaim.create!(wiki:, sentence: 'Another claim.')
        post "/courses/#{course.slug}/verify_claim/take",
             params: { verification_claim_id: other_claim.id }
        expect(response.status).to eq(200)
        post "/courses/#{course.slug}/verify_claim/response",
             params: { source_access: 'nonexistent', source_access_notes: 'No trace.' }
        expect(VerificationClaimResponse.where(user: student, course:).count).to eq(2)
      end

      it 'returns the earlier response when re-taking an already-answered claim' do
        post "/courses/#{course.slug}/verify_claim/response", params: accessed_answers
        post "/courses/#{course.slug}/verify_claim/take",
             params: { verification_claim_id: claim.id }
        expect(response.parsed_body['response']['verdict']).to eq('partial_support')
      end
    end

    it 'is forbidden for a signed-in user not enrolled in the course' do
      outsider = create(:user, username: 'Interloper')
      login_as outsider
      post "/courses/#{course.slug}/verify_claim/response", params: accessed_answers
      expect(response.status).to eq(403)
    end
  end

  describe 'GET responses' do
    let(:instructor) { create(:user, username: 'Prof') }

    before do
      create(:courses_user, course:, user: instructor,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE, real_name: 'Ada Prof')
      VerificationClaimAssignment.create!(user: student, course:, verification_claim: claim)
      VerificationClaimResponse.create!(user: student, course:, verification_claim: claim,
                                        **accessed_answers)
      # A second student who has taken a claim but not submitted.
      pending_student = create(:user, username: 'Slowpoke')
      create(:courses_user, course:, user: pending_student,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      VerificationClaimAssignment.create!(user: pending_student, course:,
                                          verification_claim: claim)
    end

    it 'lists responses and pending students for an instructor' do
      login_as instructor
      get "/courses/#{course.slug}/verify_claim/responses.json"
      expect(response.status).to eq(200)
      submitted = response.parsed_body['responses']
      expect(submitted.length).to eq(1)
      expect(submitted.first['username']).to eq('Otterfan')
      expect(submitted.first['verdict']).to eq('partial_support')
      expect(submitted.first['claim']['sentence']).to eq(claim.sentence)
      expect(response.parsed_body['pending'].first['username']).to eq('Slowpoke')
    end

    it 'counts a student as pending again once they take a new claim' do
      other_claim = VerificationClaim.create!(wiki:, sentence: 'Another claim.')
      VerificationClaimAssignment.find_by(user: student, course:)
                                 .update!(verification_claim: other_claim)
      login_as instructor
      get "/courses/#{course.slug}/verify_claim/responses.json"
      # The earlier response still shows, and the fresh claim shows as pending.
      expect(response.parsed_body['responses'].pluck('username')).to include('Otterfan')
      expect(response.parsed_body['pending'].pluck('username'))
        .to contain_exactly('Otterfan', 'Slowpoke')
    end

    it 'gives a student only their own responses and pending claims' do
      login_as student
      get "/courses/#{course.slug}/verify_claim/responses.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body['responses'].pluck('username')).to eq(['Otterfan'])
      # Slowpoke's taken-but-unsubmitted claim is not theirs to see.
      expect(response.parsed_body['pending']).to be_empty
    end

    it 'is forbidden for a signed-in user with no role in the course' do
      outsider = create(:user, username: 'Interloper')
      login_as outsider
      get "/courses/#{course.slug}/verify_claim/responses.json"
      expect(response.status).to eq(403)
    end

    it 'is allowed for admins not enrolled in the course' do
      admin = create(:admin)
      login_as admin
      get "/courses/#{course.slug}/verify_claim/responses.json"
      expect(response.status).to eq(200)
    end
  end
end
