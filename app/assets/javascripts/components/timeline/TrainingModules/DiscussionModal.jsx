import React, { useEffect, useId, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';
import Modal from '../../common/modal.jsx';
import Loading from '../../common/loading.jsx';
import { fetchTrainingModulePromise } from '../../../actions/training_actions';
import { API_FAIL } from '../../../constants';

const md = require('../../../utils/markdown_it.js').default({ openLinksExternally: true });

// A slide's title and content in the current locale, as the training pages
// show them.
const slideText = (slide) => {
  const { title, content } = slide.translations?.[I18n.locale] || slide;
  return { title, html: content ? md.render(content) : '' };
};

// Shows a discussion module's prompts, all of its slides in one, over the page
// it was opened from.
const DiscussionModal = ({ module, onClose }) => {
  const [slides, setSlides] = useState(null);
  const dispatch = useDispatch();
  const titleId = useId();
  const closeButton = useRef(null);

  useEffect(() => {
    closeButton.current?.focus();
  }, []);

  useEffect(() => {
    let active = true;
    fetchTrainingModulePromise({ module_id: module.slug })
      .then((resp) => {
        if (active) setSlides(resp.training_module.slides);
      })
      .catch((error) => {
        if (!active) return;
        dispatch({ type: API_FAIL, data: error });
        onClose();
      });
    return () => { active = false; };
  }, [module.slug]);

  // The module name heads the modal, so a lone slide's title would repeat it.
  const showSlideTitles = slides?.length > 1;

  return createPortal(
    <Modal modalClass="discussion-modal" ariaLabelledBy={titleId} onClose={onClose}>
      <div className="discussion-modal__panel">
        <div className="discussion-modal__header">
          <span className="discussion-module__icon" aria-hidden="true" />
          <div className="discussion-modal__heading">
            <span className="discussion-module__kind">{I18n.t('training.kind.discussion')}</span>
            <h2 id={titleId}>{module.translated_name}</h2>
          </div>
          <button
            type="button"
            ref={closeButton}
            className="icon-close discussion-modal__close"
            aria-label={I18n.t('application.close')}
            onClick={onClose}
          />
        </div>
        {slides ? slides.map((slide) => {
          const { title, html } = slideText(slide);
          return (
            <section key={slide.slug} className="discussion-modal__slide">
              {showSlideTitles && <h3>{title}</h3>}
              <div className="markdown" dangerouslySetInnerHTML={{ __html: html }} />
            </section>
          );
        }) : <Loading />}
        <div className="discussion-modal__actions">
          <button type="button" className="button dark" onClick={onClose}>
            {I18n.t('application.close')}
          </button>
        </div>
      </div>
    </Modal>,
    document.body
  );
};

DiscussionModal.propTypes = {
  module: PropTypes.shape({
    slug: PropTypes.string.isRequired,
    translated_name: PropTypes.string
  }).isRequired,
  onClose: PropTypes.func.isRequired
};

export default DiscussionModal;
