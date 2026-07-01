import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../common/modal.jsx';
import request from '../../utils/request';
import logErrorMessage from '../../utils/log_error_message';

const md = require('../../utils/markdown_it.js').default({ openLinksExternally: true });

// Invitation modal shown to enrolled students of a course participating in an
// active opt-in research experiment. It presents the (long) invitation message
// and the full consent form, then records the student's choice. Opting in
// installs a userscript on the student's English Wikipedia account; if their
// OAuth token lacks the required grant the server reports `reauth_required`,
// and we prompt them to re-authorize and retry the install on return.
//
// All copy is supplied by the server (`invitation.copy`, from the experiment's
// Ruby definition), so this ephemeral text stays out of the i18n pipeline.
const ExperimentOptInInvitation = ({ course, current_user }) => {
  const [invitation, setInvitation] = useState(null);
  // hidden | choice | reauth | working
  const [phase, setPhase] = useState('hidden');

  const eligible = !!(course && course.id && course.eligible_for_active_research_experiment
    && current_user && current_user.isStudent);

  const post = (slug, action) =>
    request(`/experiments/${slug}/courses/${course.id}/${action}`, { method: 'POST' })
      .then(res => res.json());

  const applyResult = (data) => {
    setPhase(data && data.reauth_required ? 'reauth' : 'hidden');
  };

  useEffect(() => {
    if (!eligible) return undefined;
    let active = true;
    (async () => {
      try {
        const res = await request(`/experiments/courses/${course.id}/invitation`);
        if (!res.ok) return;
        const data = await res.json();
        if (!active || !data.experiment_slug) return;
        setInvitation(data);
        if (data.needs_response) {
          setPhase('choice');
        } else if (data.userscript_pending) {
          // Returning from re-authorization: retry the install once.
          applyResult(await post(data.experiment_slug, 'opt_in'));
        }
      } catch (error) {
        logErrorMessage(error);
      }
    })();
    return () => { active = false; };
  }, [eligible, course.id]);

  const choose = async (action) => {
    setPhase('working');
    try {
      applyResult(await post(invitation.experiment_slug, action));
    } catch (error) {
      logErrorMessage(error);
      setPhase('hidden');
    }
  };

  if (phase === 'hidden' || phase === 'working' || !invitation) return null;

  const { copy } = invitation;

  if (phase === 'reauth') {
    const origin = encodeURIComponent(window.location.href);
    return (
      <Modal modalClass="experiment-opt-in" ariaLabel={copy.title}>
        <div className="experiment-opt-in__panel">
          <p>{copy.reauth_message}</p>
          <div className="experiment-opt-in__actions">
            <a data-method="post" href={`/users/auth/mediawiki?origin=${origin}`} className="button dark">
              {copy.reauth_button}
            </a>
          </div>
        </div>
      </Modal>
    );
  }

  return (
    <Modal modalClass="experiment-opt-in" ariaLabelledBy="experiment-opt-in-title">
      <div className="experiment-opt-in__panel">
        <h2 id="experiment-opt-in-title">{copy.title}</h2>
        <div dangerouslySetInnerHTML={{ __html: md.render(copy.message || '') }} />
        <div className="experiment-opt-in__consent" dangerouslySetInnerHTML={{ __html: md.render(copy.consent_form || '') }} />
        <div className="experiment-opt-in__actions">
          <button className="button dark" onClick={() => choose('opt_in')}>{copy.opt_in}</button>
          <button className="button" onClick={() => choose('opt_out')}>{copy.opt_out}</button>
        </div>
      </div>
    </Modal>
  );
};

ExperimentOptInInvitation.propTypes = {
  course: PropTypes.shape({
    id: PropTypes.number,
    eligible_for_active_research_experiment: PropTypes.bool
  }).isRequired,
  current_user: PropTypes.shape({
    isStudent: PropTypes.bool
  }).isRequired
};

export default ExperimentOptInInvitation;
