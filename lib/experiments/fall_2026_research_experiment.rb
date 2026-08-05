# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/experiments/opt_in_experiment"

# The Fall 2026 research study ("Ribeiro experiment").
#
# Eligible courses are ClassroomProgramCourses whose inferred term is Fall 2026,
# on the Wiki Education dashboard. A student who opts in is shown the import line
# and a link to their own common.js, and installs the userscript themselves; the
# Dashboard confirms it afterwards (see CheckExperimentUserscript).
class Fall2026ResearchExperiment < OptInExperiment
  SLUG = 'fall_2026_research'

  # The userscript students install. As a user JS page it is editable only by its
  # owner and interface admins, so the code participants run cannot be altered by
  # anyone else.
  USERSCRIPT_PAGE = 'User:Sage_(Wiki_Ed)/fall2026experiment.js'

  USERSCRIPT_IMPORT_LINE = "importScript('#{USERSCRIPT_PAGE}');"

  # Student-facing invitation copy, shown in a modal. `message`, `consent_form`
  # and `install_message` are rendered as Markdown. Kept here (not in en.yml) so
  # this ephemeral experiment text stays out of the translation pipeline.
  STUDENT_INVITATION_COPY = {
    title: 'Research Study',
    message: <<~MESSAGE,
      You are invited to take part in a research study.

      Researchers at Princeton University, working with Wiki Education, are studying a tool that gives feedback while you edit Wikipedia (Princeton University IRB #19959). If you take part, a small tool may show short feedback while you edit, such as a reminder to add a citation or feedback on whether sources you add are appropriate. The tool never changes your text and never stops you from saving an article. If you choose to participate, you'll be prompted to make a simple edit to enable the experiment.

      Taking part is voluntary and will not impact your course grade in any way. No individual data will be shared with your course instructor(s). There is no compensation. To take part, you must be 18 or older and live in the United States.

      To learn more about the study and what data is collected, and to decide whether to take part, please read the consent form.
    MESSAGE
    consent_form: File.read("#{__dir__}/fall_2026_consent_form.md"),
    opt_in: 'I consent',
    opt_out: 'No',
    install_title: 'Install the experiment script',
    install_message: <<~INSTALL,
      To enable the experiment, copy the line below, click 'Install script', paste it to your common.js page, then "Publish changes".
    INSTALL
    install_button: 'Install script',
    install_verify_button: 'Verify experiment script',
    install_not_found: "We couldn't find the expected experiment script installed on your account."
  }.freeze

  def slug
    SLUG
  end

  def eligible_course?(course)
    return false unless Features.wiki_ed?
    return false unless course.is_a?(ClassroomProgramCourse)

    course.inferred_term == 'fall_2026'
  end

  # Held back until the userscript is ready to hand to students. Instructors can
  # opt their courses in before then; those courses simply have no students
  # invited yet.
  def student_invitations_open?
    Features.fall_2026_research_student_optin?
  end

  def userscript_import_line
    USERSCRIPT_IMPORT_LINE
  end

  # Substring that identifies the userscript on a student's common.js.
  def userscript_marker
    USERSCRIPT_PAGE
  end

  def userscript_target_page(user)
    "User:#{user.username}/common.js"
  end

  # Edit-form URL for the student's own common.js. The edit box cannot be
  # prefilled: MediaWiki's `preload` is gated on
  # ContentHandler::supportsPreloadContent, which is false for the javascript
  # content model (only wikitext and JSON support it). So the student is shown
  # the import line and pastes it in themselves.
  def userscript_install_url(user)
    query = { title: userscript_target_page(user), action: 'edit', summary: edit_summary }
    "#{en_wiki.base_url}/w/index.php?#{query.to_query}"
  end

  def edit_summary
    'Add userscript for participating in Wiki Education research study'
  end

  def student_invitation_copy
    STUDENT_INVITATION_COPY
  end

  private

  def en_wiki
    Wiki.get_or_create(language: 'en', project: 'wikipedia')
  end
end
