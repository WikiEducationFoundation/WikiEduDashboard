# frozen_string_literal: true

require 'rails_helper'

describe PushCourseApplicationToSalesforce do
  let(:course_salesforce_id) { 'a0f1a00000ABCDEFGH' }
  let(:course) { create(:fellows_cohort, flags: { salesforce_id: course_salesforce_id }) }
  let(:user) { create(:user, username: 'Election_scholar', email: 'scholar@example.edu') }
  let(:client) { instance_double(Restforce::Data::Client) }
  let(:existing_contacts) { [] }
  let(:existing_course_contacts) { [] }
  let(:application) do
    CourseApplicationForm.create!(course:, open: true)
    answers = built_in_application_answers(
      first_name: 'Dana', last_name: 'Whitfield', preferred_name: 'Dee',
      pronouns: 'She/her', ethnicity: ['White', 'Something else'],
      ethnicity_other: 'Cajun', background: 'Historian of elections', title: 'Professor'
    )
    # No pushes while setting up; each example pushes explicitly.
    allow(PushCourseApplicationToSalesforceWorker).to receive(:perform_async)
    SubmitCourseApplication.new(course:, user:, answers:).application
  end

  before do
    allow(Restforce).to receive(:new).and_return(client)
    allow(client).to receive(:query) do |soql|
      case soql
      when /FROM RecordType .*'Contact'/ then [double(Id: 'contact-record-type')]
      when /FROM RecordType .*'Course_Contact__c'/ then [double(Id: 'participant-record-type')]
      when /FROM Contact / then existing_contacts
      when /FROM Course_Contact__c / then existing_course_contacts
      end
    end
    allow(client).to receive(:create!).with('Contact', anything).and_return('new-contact')
    allow(client).to receive(:create!).with('Course_Contact__c', anything)
                                      .and_return('new-course-contact')
    allow(client).to receive(:update!).and_return(true)
  end

  context 'with no Contact for the applicant\'s email' do
    before { described_class.new(application) }

    it 'creates one as the FormAssembly connector did, plus their username' do
      expect(client).to have_received(:create!).with('Contact', hash_including(
        Form_Assembly_First_Name__c: 'Dana', LastName: 'Whitfield',
        Nickname__c: 'Dee', Title: 'Professor', Pronouns__c: 'She/Her',
        Ethnicity__c: 'White;Other', Ethnicity_Other__c: 'Cajun',
        npe01__WorkEmail__c: 'scholar@example.edu', npe01__Preferred_Email__c: 'Work',
        Wiki_Username__c: 'Election_scholar', RecordTypeId: 'contact-record-type'
      ))
      expect(client).to have_received(:create!)
        .with('Contact', hash_excluding(:FirstName, :Email))
    end

    it 'looks for the email in all three of the Contact\'s email fields' do
      email = "'scholar@example.edu'"
      expect(client).to have_received(:query).with(
        /Email = #{email} OR npe01__WorkEmail__c = #{email} OR npe01__HomeEmail__c = #{email}/
      )
    end

    it 'leaves out answers to questions the applicant was not shown' do
      expect(client).to have_received(:create!)
        .with('Contact', hash_excluding(:Pronouns_Other__c))
    end

    it 'creates the Course Contact as FormAssembly did, with the Course Contact answers' do
      expect(client).to have_received(:create!).with('Course_Contact__c', hash_including(
        Contact__c: 'new-contact', Course__c: course_salesforce_id,
        RecordTypeId: 'participant-record-type', Role__c: 'Scholar or Scientist',
        Scholars_Scientists_Status__c: 'Applied', Background__c: 'Historian of elections',
        Title__c: 'Professor',
        Application_Response_URL__c: end_with("/applications/#{application.id}")
      ))
    end

    context 'with answers longer than their Salesforce fields' do
      let(:application) do
        CourseApplicationForm.create!(course:, open: true)
        answers = built_in_application_answers(background: 'a' * 300, title: 't' * 100)
        allow(PushCourseApplicationToSalesforceWorker).to receive(:perform_async)
        SubmitCourseApplication.new(course:, user:, answers:).application
      end

      it 'cuts each to fit its field, and keeps the full answer on the Dashboard' do
        expect(client).to have_received(:create!).with('Course_Contact__c', hash_including(
          Background__c: "#{'a' * 254}…", Title__c: "#{'t' * 79}…"
        ))
        # Contact.Title holds 128 characters.
        expect(client).to have_received(:create!)
          .with('Contact', hash_including(Title: 't' * 100))
        background = CourseApplicationDefaultQuestions.entry(:background).question
        expect(Rapidfire::Answer.find_by(question_id: background.id).answer_text)
          .to eq('a' * 300)
      end
    end

    it 'saves both Salesforce ids on the application' do
      expect(application.reload).to have_attributes(
        salesforce_contact_id: 'new-contact', salesforce_course_contact_id: 'new-course-contact'
      )
    end
  end

  context 'when the applicant has no email' do
    let(:user) { create(:user, username: 'Election_scholar', email: nil) }
    # What a search on a blank email could match: some Contact without one.
    let(:existing_contacts) { [double(Id: 'unrelated-contact', Wiki_Username__c: nil)] }

    before { described_class.new(application) }

    it 'creates a new Contact rather than searching by email' do
      expect(client).not_to have_received(:query).with(/FROM Contact /)
      expect(client).not_to have_received(:update!).with('Contact', anything)
      expect(application.reload.salesforce_contact_id).to eq('new-contact')
    end
  end

  context 'with a Contact for the applicant\'s email' do
    let(:existing_contacts) { [double(Id: 'old-contact', Wiki_Username__c: nil)] }

    before { described_class.new(application) }

    it 'updates it as the connector did, filling in the blank username' do
      expect(client).to have_received(:update!).with('Contact', hash_including(
        Id: 'old-contact', LastName: 'Whitfield', Pronouns__c: 'She/Her',
        npe01__Preferred_Email__c: 'Work', Wiki_Username__c: 'Election_scholar'
      ))
      expect(client).not_to have_received(:create!).with('Contact', anything)
      expect(application.reload.salesforce_contact_id).to eq('old-contact')
    end
  end

  context 'with a Contact that already has a Wikipedia username' do
    let(:existing_contacts) { [double(Id: 'old-contact', Wiki_Username__c: 'Other_account')] }

    before { described_class.new(application) }

    it 'keeps it' do
      expect(client).to have_received(:update!)
        .with('Contact', hash_excluding(:Wiki_Username__c))
    end
  end

  context 'with a Course Contact already linking them to the course' do
    let(:existing_contacts) { [double(Id: 'old-contact', Wiki_Username__c: 'Election_scholar')] }
    let(:existing_course_contacts) { [double(Id: 'interested-record')] }

    before { described_class.new(application) }

    it 'updates that record instead of adding another' do
      expect(client).to have_received(:update!).with('Course_Contact__c', hash_including(
        Id: 'interested-record', Scholars_Scientists_Status__c: 'Applied'
      ))
      expect(client).not_to have_received(:create!).with('Course_Contact__c', anything)
      expect(application.reload.salesforce_course_contact_id).to eq('interested-record')
    end
  end

  context 'once the application is in Salesforce' do
    before do
      application.update!(salesforce_contact_id: 'old-contact',
                          salesforce_course_contact_id: 'course-contact')
    end

    it 'sends Invited on acceptance' do
      application.update!(status: :accepted)
      described_class.new(application)
      expect(client).to have_received(:update!).with(
        'Course_Contact__c', Id: 'course-contact', Scholars_Scientists_Status__c: 'Invited'
      )
      expect(client).not_to have_received(:create!)
    end

    it 'sends Not accepted on decline' do
      application.update!(status: :declined)
      described_class.new(application)
      expect(client).to have_received(:update!).with(
        'Course_Contact__c', Id: 'course-contact', Scholars_Scientists_Status__c: 'Not accepted'
      )
    end
  end

  it 'does nothing for a course not linked to Salesforce' do
    course.update!(flags: {})
    described_class.new(application)
    expect(Restforce).not_to have_received(:new)
  end

  it 'does nothing on the Programs & Events Dashboard' do
    application
    allow(Features).to receive(:wiki_ed?).and_return(false)
    described_class.new(application)
    expect(Restforce).not_to have_received(:new)
  end

  it 'quotes SOQL strings' do
    user.update!(email: "o'brien@example.edu")
    described_class.new(application)
    expect(client).to have_received(:query).with(/Email = 'o\\'brien@example.edu'/)
  end
end
