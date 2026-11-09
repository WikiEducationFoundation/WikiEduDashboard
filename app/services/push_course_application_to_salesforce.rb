# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/course_application_default_questions"

# Records a Scholars & Scientists application in Salesforce the way the
# FormAssembly form's connector did: the applicant's Contact (the most recently
# modified one with their email as its Email, Work Email or Personal Email, or a
# new one), and a Participant-type Course Contact linking them to the course's
# Course__c record, with their status and their answers to the built-in
# questions that map to Salesforce fields (see
# config/course_application_default_questions.yml). Beyond the connector, it
# fills in the Contact's Wikipedia username when that's blank.
#
# Run on submission and again on each decision. Each Salesforce id is saved on
# the application as soon as it's known, so a retry never creates a second
# record. A course not yet linked to Salesforce is skipped; linking it pushes
# its applications then.
class PushCourseApplicationToSalesforce
  # Dashboard status → Course Contact Scholars_Scientists_Status__c.
  STATUSES = { 'submitted' => 'Applied', 'accepted' => 'Invited',
               'declined' => 'Not accepted' }.freeze
  ROLE = 'Scholar or Scientist'
  CONTACT_RECORD_TYPE = 'Program Participant'
  COURSE_CONTACT_RECORD_TYPE = 'Participant'

  def initialize(application)
    return unless Features.wiki_ed?
    @application = application
    @course = application.course
    return unless @course.flags[:salesforce_id]

    @client = Restforce.new(SalesforceCredentials.get)
    push
  end

  private

  def push
    contact_id = @application.salesforce_contact_id || find_or_create_contact
    if @application.salesforce_course_contact_id
      @client.update!('Course_Contact__c', Id: @application.salesforce_course_contact_id,
                                           Scholars_Scientists_Status__c: status)
    else
      create_course_contact(contact_id)
    end
  end

  ###########
  # Contact #
  ###########

  def find_or_create_contact
    contact = matching_contact
    contact_id = contact ? update_contact(contact) : @client.create!('Contact', new_contact_fields)
    @application.update!(salesforce_contact_id: contact_id)
    contact_id
  end

  def update_contact(contact)
    fields = contact_fields
    # Only filled in, never replaced: a Contact can have an alternate username.
    fields[:Wiki_Username__c] = @application.user.username if contact.Wiki_Username__c.blank?
    @client.update!('Contact', fields.merge(Id: contact.Id))
    contact.Id
  end

  def matching_contact
    email = soql_string(@application.user.email)
    @client.query('SELECT Id, Wiki_Username__c FROM Contact ' \
                  "WHERE Email = #{email} OR npe01__WorkEmail__c = #{email} " \
                  "OR npe01__HomeEmail__c = #{email} " \
                  'ORDER BY LastModifiedDate DESC LIMIT 1').first
  end

  def new_contact_fields
    contact_fields.merge(Wiki_Username__c: @application.user.username)
  end

  # As the connector set them, for new and existing Contacts alike. The first
  # name goes to Form_Assembly_First_Name__c, not FirstName (see the YAML);
  # the nonprofit pack sets Email from the preferred Work Email.
  def contact_fields
    answer_fields('Contact').merge(
      npe01__WorkEmail__c: @application.user.email, npe01__Preferred_Email__c: 'Work',
      RecordTypeId: record_type_id('Contact', CONTACT_RECORD_TYPE)
    )
  end

  ##################
  # Course Contact #
  ##################

  # Reuses a Course Contact staff already made for this person and course (an
  # "Interested" record, say) rather than adding a second.
  def create_course_contact(contact_id)
    existing_id = existing_course_contact_id(contact_id)
    fields = course_contact_fields(contact_id)
    if existing_id
      @client.update!('Course_Contact__c', fields.merge(Id: existing_id))
    else
      existing_id = @client.create!('Course_Contact__c', fields)
    end
    @application.update!(salesforce_course_contact_id: existing_id)
  end

  def existing_course_contact_id(contact_id)
    @client.query('SELECT Id FROM Course_Contact__c ' \
                  "WHERE Contact__c = #{soql_string(contact_id)} " \
                  "AND Course__c = #{soql_string(@course.flags[:salesforce_id])} " \
                  'LIMIT 1').first&.Id
  end

  def course_contact_fields(contact_id)
    answer_fields('Course_Contact__c').merge(
      Contact__c: contact_id, Course__c: @course.flags[:salesforce_id],
      RecordTypeId: record_type_id('Course_Contact__c', COURSE_CONTACT_RECORD_TYPE),
      Role__c: ROLE, Scholars_Scientists_Status__c: status,
      Application_Submission_Date__c: @application.created_at.iso8601,
      Application_Response_URL__c: review_url
    )
  end

  def status
    STATUSES.fetch(@application.status)
  end

  # Admin-only, like the FormAssembly response link it replaces.
  def review_url
    "https://#{ENV['dashboard_url']}/courses/#{@course.slug}/applications/#{@application.id}"
  end

  ###########
  # Answers #
  ###########

  # { Field: value } for each built-in question answered whose Salesforce
  # field is on `object`.
  def answer_fields(object)
    CourseApplicationDefaultQuestions.entries.each_with_object({}) do |entry, fields|
      answer = answers_by_question_id[entry.question.id]
      next if answer.nil? || answer.answer_text.blank?

      entry.salesforce_fields.each do |target|
        target_object, field = target.split('.')
        next unless target_object == object
        fields[field.to_sym] = fit_to_field(target, salesforce_value(entry, answer))
      end
    end
  end

  # Checkbox answers become a multi-select picklist value (`;`-separated);
  # options with a different Salesforce picklist value are translated.
  def salesforce_value(entry, answer)
    values = answer.answer_text.split(Rapidfire.answers_delimiter).map do |value|
      entry.salesforce_values.fetch(value, value)
    end
    values.join(';')
  end

  # Salesforce rejects a value longer than its field, so a long answer is cut
  # to fit. The full answer stays on the Dashboard, at the review URL.
  def fit_to_field(target, value)
    length = CourseApplicationDefaultQuestions.salesforce_field_length(target)
    length ? value.truncate(length, omission: '…') : value
  end

  def answers_by_question_id
    @answers_by_question_id ||= Rapidfire::Answer
                                .joins(:answer_group)
                                .where(rapidfire_answer_groups: {
                                         course_application_id: @application.id,
                                         question_group_id: CourseApplicationDefaultQuestions::GROUP_ID
                                       })
                                .index_by(&:question_id)
  end

  ###########
  # Helpers #
  ###########

  def record_type_id(object, name)
    @client.query('SELECT Id FROM RecordType ' \
                  "WHERE SobjectType = #{soql_string(object)} AND Name = #{soql_string(name)} " \
                  'LIMIT 1').first&.Id
  end

  # A quoted SOQL string literal.
  def soql_string(value)
    "'#{value.to_s.gsub('\\') { '\\\\' }.gsub("'") { "\\'" }}'"
  end
end
