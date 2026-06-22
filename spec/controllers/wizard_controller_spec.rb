# frozen_string_literal: true

require 'rails_helper'

describe WizardController, type: :controller do
  describe '#submit_wizard' do
    let(:course) { create(:course) }
    let(:wizard_params) do
      { course_id: course.slug, wizard_id: 'researchwrite',
        wizard_output: { output: [], logic: ['instructor_learner'], tags: [] } }
    end

    def student_role_exists_for(user)
      CoursesUsers.exists?(course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    context 'when an instructor selects the learning-to-edit option' do
      let(:instructor) { create(:user) }

      before do
        create(:courses_user, course:, user: instructor,
                              role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        allow(controller).to receive(:current_user).and_return(instructor)
      end

      it 'enrolls the instructor as a student' do
        post :submit_wizard, params: wizard_params
        expect(student_role_exists_for(instructor)).to be true
      end
    end

    context 'when an admin who is not an instructor submits the wizard' do
      let(:admin) { create(:admin) }

      before { allow(controller).to receive(:current_user).and_return(admin) }

      it 'does not enroll the admin as a student' do
        post :submit_wizard, params: wizard_params
        expect(student_role_exists_for(admin)).to be false
      end
    end
  end
end
