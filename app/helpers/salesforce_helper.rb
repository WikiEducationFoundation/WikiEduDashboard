# frozen_string_literal: true

module SalesforceHelper
  def program_id(course)
    case course.type
    when 'ClassroomProgramCourse', 'LegacyCourse'
      ENV['SF_CLASSROOM_PROGRAM_ID']
    when 'VisitingScholarship'
      ENV['SF_VISITING_SCHOLARS_PROGRAM_ID']
    when 'FellowsCohort'
      ENV['SF_WIKIPEDIA_FELLOWS_PROGRAM_ID']
    end
  end
end
