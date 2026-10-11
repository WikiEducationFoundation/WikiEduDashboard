import React, { useId, useRef, useState } from 'react';
import PropTypes from 'prop-types';
import DiscussionModal from './DiscussionModal';

// A discussion module is a set of prompts for a class discussion, not a
// training to work through: its slides open in a modal right where it is
// listed, rather than on the training pages.
const DiscussionModule = ({ module }) => {
  const [open, setOpen] = useState(false);
  const viewButton = useRef(null);
  const nameId = useId();

  const close = () => {
    setOpen(false);
    viewButton.current?.focus();
  };

  return (
    <div className="discussion-module">
      <span className="discussion-module__icon" aria-hidden="true" />
      <div className="discussion-module__text">
        <span className="discussion-module__kind">{I18n.t('training.kind.discussion')}</span>
        <span className="discussion-module__name" id={nameId}>{module.translated_name}</span>
      </div>
      <button
        type="button"
        ref={viewButton}
        className="button discussion-module__view"
        aria-haspopup="dialog"
        aria-describedby={nameId}
        onClick={() => setOpen(true)}
      >
        {I18n.t('training_status.view')}
      </button>
      {open && <DiscussionModal module={module} onClose={close} />}
    </div>
  );
};

DiscussionModule.propTypes = {
  module: PropTypes.shape({
    slug: PropTypes.string.isRequired,
    translated_name: PropTypes.string
  }).isRequired
};

export default DiscussionModule;
