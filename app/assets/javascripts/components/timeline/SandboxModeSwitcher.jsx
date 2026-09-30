import React, { useEffect, useRef } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';

import { switchSandboxMode } from '../../actions/wizard_block_actions';
import { initiateConfirm } from '../../actions/confirm_actions';

// Admin-only: move a course between drafting in sandboxes and editing live
// articles, for when an instructor changes their mind after course creation.
//
// This is deliberately not the same thing as the no_sandboxes toggle on the
// Overview page. That sets the course flag alone; this also rewrites the
// `sandboxes` tag and swaps the timeline blocks that exist in two variants, so
// the course does not end up telling students to do the opposite of what it is
// configured for.
const titlesOf = entries => entries.map(entry => entry.title).join(', ');

// Always rendered, as a live region: assistive technology only announces
// changes inside a live region that already existed, so the container has to
// be in the DOM before the report arrives, not created along with it.
const Report = ({ report }) => (
  <div className="sandbox-mode__report" role="status">
    {report && report.removed.length > 0 && (
      <p>{I18n.t('timeline.sandbox_mode_removed')}: {titlesOf(report.removed)}</p>
    )}
    {report && report.added.length > 0 && (
      <p>{I18n.t('timeline.sandbox_mode_added')}: {titlesOf(report.added)}</p>
    )}
    {report && report.unmatched.length > 0 && (
      <p className="sandbox-mode__warning">
        {I18n.t('timeline.sandbox_mode_unmatched')}: {titlesOf(report.unmatched)}
      </p>
    )}
    {report && report.unresolved.length > 0 && (
      <p className="sandbox-mode__warning">
        {I18n.t('timeline.sandbox_mode_unresolved')}: {titlesOf(report.unresolved)}
      </p>
    )}
  </div>
);

Report.propTypes = { report: PropTypes.object };

const SandboxModeSwitcher = ({ course }) => {
  const dispatch = useDispatch();
  const { switching, lastSwitch } = useSelector(state => state.wizardBlocks);
  const noSandboxes = Boolean(course.no_sandboxes);
  const buttonRef = useRef(null);
  const wasSwitching = useRef(false);

  // The confirm dialog drops focus on <body> when it closes. Once the switch
  // has finished, or failed, put focus back on the button that started it, so
  // that a keyboard or screen reader user is back where they were, next to the
  // report.
  useEffect(() => {
    if (wasSwitching.current && !switching) buttonRef.current?.focus();
    wasSwitching.current = switching;
  }, [switching]);

  // Only this course's report: the store outlives navigation between courses.
  const report = lastSwitch && lastSwitch.courseSlug === course.slug ? lastSwitch : null;

  const switchLabel = noSandboxes
    ? I18n.t('timeline.sandbox_mode_switch_to_sandboxes')
    : I18n.t('timeline.sandbox_mode_switch_to_live');

  // The confirm dialog takes its accessible name from confirmMessage, so that
  // is the action being confirmed; the generic question sits above it.
  const confirmSwitch = () => dispatch(initiateConfirm({
    confirmMessage: switchLabel,
    explanation: I18n.t('application.confirm_generic'),
    onConfirm: () => dispatch(switchSandboxMode(course.slug, !noSandboxes))
  }));

  const current = noSandboxes
    ? I18n.t('timeline.sandbox_mode_current_live')
    : I18n.t('timeline.sandbox_mode_current_sandboxes');

  return (
    // Labelled as a group rather than with a heading: the sidebar sits after
    // the weeks' h2s and the blocks' h3s, so a heading here would skip levels.
    <div className="sandbox-mode" role="group" aria-label={I18n.t('timeline.sandbox_mode')}>
      <p className="sandbox-mode__label">{I18n.t('timeline.sandbox_mode')}</p>
      <p className="muted">{current}</p>
      <button
        type="button"
        className="button border button--block"
        disabled={switching}
        onClick={confirmSwitch}
        ref={buttonRef}
      >
        {switchLabel}
      </button>
      <Report report={report} />
    </div>
  );
};

SandboxModeSwitcher.propTypes = {
  course: PropTypes.object.isRequired
};

export default SandboxModeSwitcher;
