import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../common/modal.jsx';
import request from '../../utils/request';
import logErrorMessage from '../../utils/log_error_message';

const md = require('../../utils/markdown_it.js').default({ openLinksExternally: true });

// Invitation modal shown to enrolled students of a course participating in an
// active opt-in research experiment. It presents the (long) invitation message
// and the full consent form, then records the student's choice.
//
// Opting in installs nothing on the student's behalf: the Dashboard has no OAuth
// grant to edit user JS pages. Instead the student gets a link to their own
// English Wikipedia common.js, preloaded with the import line where MediaWiki
// allows it, and saves it themselves. The server confirms the script is really
// there by reading the page, so the install step reappears until it is.
//
// All copy is supplied by the server (`invitation.copy`, from the experiment's
// Ruby definition), so this ephemeral text stays out of the i18n pipeline.
const ExperimentOptInInvitation = ({ course, current_user }) => {
  const [invitation, setInvitation] = useState(null);
  const [userscript, setUserscript] = useState(null);
  // hidden | choice | install | working
  const [phase, setPhase] = useState('hidden');
  const [checked, setChecked] = useState(false);

  const eligible = !!(course && course.id && course.eligible_for_active_research_experiment
    && current_user && current_user.isStudent);

  const fetchInvitation = async () => {
    const res = await request(`/experiments/courses/${course.id}/invitation`);
    if (!res.ok) return null;
    return res.json();
  };

  // A `userscript` payload means the script is not on the student's common.js
  // yet; its absence means we are done with them.
  const applyResult = (data) => {
    setUserscript(data && data.userscript);
    setPhase(data && data.userscript ? 'install' : 'hidden');
  };

  useEffect(() => {
    if (!eligible) return undefined;
    let active = true;
    (async () => {
      try {
        const data = await fetchInvitation();
        if (!active || !data || !data.experiment_slug) return;
        setInvitation(data);
        if (data.needs_response) {
          setPhase('choice');
        } else {
          applyResult(data);
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
      const res = await request(
        `/experiments/${invitation.experiment_slug}/courses/${course.id}/${action}`,
        { method: 'POST' }
      );
      applyResult(await res.json());
    } catch (error) {
      logErrorMessage(error);
      setPhase('hidden');
    }
  };

  // Re-read the student's common.js. Once the line is there the server stops
  // returning an install payload and the modal closes for good.
  const recheck = async () => {
    setPhase('working');
    try {
      const data = await fetchInvitation();
      setChecked(true);
      if (!data) {
        setPhase('install');
        return;
      }
      applyResult(data);
    } catch (error) {
      logErrorMessage(error);
      setPhase('install');
    }
  };

  if (phase === 'hidden' || phase === 'working' || !invitation) return null;

  const { copy } = invitation;

  if (phase === 'install') {
    const instructions = userscript.preload ? copy.install_message : copy.install_message_manual;
    return (
      <Modal modalClass="experiment-opt-in" ariaLabelledBy="experiment-opt-in-title">
        <div className="experiment-opt-in__panel">
          <h2 id="experiment-opt-in-title">{copy.install_title}</h2>
          <div dangerouslySetInnerHTML={{ __html: md.render(instructions || '') }} />
          {!userscript.preload
            && <pre className="experiment-opt-in__snippet">{userscript.import_line}</pre>}
          {checked && <p className="experiment-opt-in__not-found">{copy.install_not_found}</p>}
          <div className="experiment-opt-in__actions">
            <a
              href={userscript.install_url}
              target="_blank"
              rel="noopener noreferrer"
              className="button dark"
            >
              {copy.install_button}
            </a>
            <button className="button" onClick={recheck}>{copy.install_verify_button}</button>
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
