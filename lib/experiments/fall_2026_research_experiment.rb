# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/experiments/opt_in_experiment"

# The Fall 2026 research study ("Ribeiro experiment").
#
# Eligible courses are ClassroomProgramCourses whose inferred term is Fall 2026,
# on the Wiki Education dashboard. Opting a student in installs a userscript on
# their English Wikipedia account (see InstallExperimentUserscript).
class Fall2026ResearchExperiment < OptInExperiment
  SLUG = 'fall_2026_research'

  # Student-facing invitation copy, shown in a modal. `message` and
  # `consent_form` are rendered as Markdown. Kept here (not in en.yml) so this
  # ephemeral experiment text stays out of the translation pipeline.
  STUDENT_INVITATION_COPY = {
    title: 'Research Study',
    message: <<~MESSAGE,
      You are invited to take part in a research study.

      Researchers at Princeton University, working with Wiki Education, are studying a tool that gives feedback while you edit Wikipedia (Princeton University IRB #XXXXX). If you take part, a small tool may show short feedback while you edit, such as a reminder to add a citation or feedback on whether sources you add are appropriate. The tool never changes your text and never stops you from saving an article. The tool will be installed automatically for your Wikipedia account if you choose to participate.

      Taking part is voluntary and will not impact your course grade in any way. No individual data will be shared with your course instructor(s). There is no compensation. To take part, you must be 18 or older and live in the United States.

      To learn more about the study and what data is collected, and to decide whether to take part, please read the consent form.
    MESSAGE
    consent_form: File.read("#{__dir__}/fall_2026_consent_form.md"),
    opt_in: 'Yes',
    opt_out: 'No',
    reauth_message: 'There was a problem installing the tool. Please log in again to authorize it.',
    reauth_button: 'Log in again'
  }.freeze

  def slug
    SLUG
  end

  def eligible_course?(course)
    return false unless Features.wiki_ed?
    return false unless course.is_a?(ClassroomProgramCourse)

    course.inferred_term == 'fall_2026'
  end

  def userscript_import_line
    "importScript('User:TestAccount4454/checkstest.js');"
  end

  def edit_summary
    'Add userscript for participating in Wiki Education reseach study'
  end

  def student_invitation_copy
    STUDENT_INVITATION_COPY
  end

  private

  def intervention(experiment_courses_user)
    InstallExperimentUserscript.new(experiment_courses_user, self).status
  end
end
