import React, { useState } from 'react';
import PropTypes from 'prop-types';

const parseArticleTitle = (input) => {
  const urlMatch = input.match(/\/wiki\/([^#?]+)/);
  if (urlMatch) return decodeURIComponent(urlMatch[1].replace(/_/g, ' '));
  return input.trim();
};

const ArticleTitleInputModal = ({ block_id, module_id, verifyArticle, onVerified, onClose }) => {
  const [inputValue, setInputValue] = useState('');
  const [status, setStatus] = useState('idle'); // idle | loading | error | success
  const [errorMessage, setErrorMessage] = useState('');

  const handleSubmit = () => {
    const articleTitle = parseArticleTitle(inputValue);
    if (!articleTitle) return;
    setStatus('loading');
    verifyArticle(block_id, module_id, articleTitle)
      .then((resp) => {
        if (resp.status === 'verified') {
          setStatus('success');
          setTimeout(() => onVerified(articleTitle), 1500);
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
                onChange={e => setInputValue(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder={I18n.t('training.article_title_input.placeholder')}
                disabled={status === 'loading'}
              />
              {status === 'error' && (
                <p className="alert-content alert-content--error">{errorMessage}</p>
              )}
              <div className="alert-button-container">
                <button className="alert-button" onClick={onClose}>
                  {I18n.t('application.cancel')}
                </button>
                <button
                  className="btn btn-primary"
                  onClick={handleSubmit}
                  disabled={status === 'loading' || !inputValue.trim()}
                >
                  {status === 'loading' ? I18n.t('training.article_title_input.checking') : I18n.t('training.article_title_input.verify')}
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
