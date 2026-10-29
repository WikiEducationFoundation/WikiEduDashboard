import React, { useState } from 'react';
import PropTypes from 'prop-types';

const ArticleTitleInputModal = ({ block_id, module_id, verifyArticle, onVerified, onClose }) => {
  const [inputValue, setInputValue] = useState('');
  const [status, setStatus] = useState('idle'); // idle | loading | error | confirm | success
  const [errorMessage, setErrorMessage] = useState('');
  // A page the student edited that isn't a mainspace article, which they have
  // to confirm before it counts.
  const [pageToConfirm, setPageToConfirm] = useState(null);

  // The server works out the article from a title or any kind of wiki URL.
  const handleSubmit = () => {
    const articleInput = inputValue.trim();
    if (!articleInput) return;
    const confirmed = status === 'confirm';
    setStatus('loading');
    verifyArticle(block_id, module_id, articleInput, confirmed)
      .then((resp) => {
        if (resp.status === 'verified') {
          setStatus('success');
          setTimeout(() => onVerified(resp.article_title), 1500);
        } else if (resp.status === 'confirm') {
          setStatus('confirm');
          setPageToConfirm({ title: resp.article_title, url: resp.article_url, message: resp.message });
        } else {
          setStatus('error');
          setErrorMessage(resp.message);
        }
      })
      .catch(() => {
        setStatus('error');
        setErrorMessage(I18n.t('application.error_saving'));
      });
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') handleSubmit();
  };

  // A confirmation is for the page that was found, so a new input needs checking again.
  const handleChange = (e) => {
    setInputValue(e.target.value);
    if (status === 'confirm') setStatus('idle');
  };

  let submitLabel = I18n.t('training.article_title_input.verify');
  if (status === 'loading') submitLabel = I18n.t('training.article_title_input.checking');
  if (status === 'confirm') submitLabel = I18n.t('training.article_title_input.submit_anyway');

  return (
    // eslint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-static-element-interactions
    <div className="blur-backdrop-for-alert-box" onClick={onClose}>
      {/* eslint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-static-element-interactions */}
      <div className="alert-box-container" onClick={e => e.stopPropagation()}>
        <div className="alert-box">
          <h2 className="alert-title">{I18n.t('training.article_title_input.modal_title')}</h2>
          {status === 'success' ? (
            <p className="alert-content alert-content--success">
              {I18n.t('training.article_title_input.success')}
            </p>
          ) : (
            <>
              <input
                type="text"
                className="alert-box__input"
                value={inputValue}
                onChange={handleChange}
                onKeyDown={handleKeyDown}
                placeholder={I18n.t('training.article_title_input.placeholder')}
                disabled={status === 'loading'}
              />
              {status === 'error' && (
                <p className="alert-content alert-content--error">{errorMessage}</p>
              )}
              {status === 'confirm' && (
                <>
                  <p className="alert-content alert-content--warning">
                    <a href={pageToConfirm.url} target="_blank" rel="noopener noreferrer">{pageToConfirm.title}</a>
                  </p>
                  <p className="alert-content alert-content--warning">{pageToConfirm.message}</p>
                </>
              )}
              <div className="alert-button-container">
                <button className="alert-button" onClick={onClose}>
                  {I18n.t('application.cancel')}
                </button>
                {/* The modal appears in both the main and the training layouts, which
                    each style only their own button classes. */}
                <button
                  className="button dark btn btn-primary"
                  onClick={handleSubmit}
                  disabled={status === 'loading' || !inputValue.trim()}
                >
                  {submitLabel}
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

ArticleTitleInputModal.propTypes = {
  block_id: PropTypes.number,
  module_id: PropTypes.string.isRequired,
  verifyArticle: PropTypes.func.isRequired,
  onVerified: PropTypes.func.isRequired,
  onClose: PropTypes.func.isRequired,
};

export default ArticleTitleInputModal;
