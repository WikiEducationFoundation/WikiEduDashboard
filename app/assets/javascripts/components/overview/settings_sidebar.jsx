import React, { useEffect } from 'react';
import ReactDOM from 'react-dom';

const SettingsSidebar = (props) => {
  const { modalOpen, toggleModal, articleViewerSettingsOption, setArticleViewerSettingsOption } = props;

  useEffect(() => {
    if (!modalOpen) return;

    const handleEsc = (e) => {
      if (e.key === 'Escape') {
        toggleModal();
      }
    };

    window.addEventListener('keydown', handleEsc);
    return () => window.removeEventListener('keydown', handleEsc);
  }, [modalOpen, toggleModal]);

  if (!modalOpen) return null;

  const handleBackdropClick = (e) => {
    e.stopPropagation();
    toggleModal();
  };

  const sidebarContent = (
    <>
      <div
        onClick={handleBackdropClick}
        className="viewer_overlay"
      />
      <div
        className="viewer_setting_container"
        style={{
          transform: modalOpen ? 'translateX(0)' : 'translateX(100%)',
          transition: 'transform 0.4s cubic-bezier(0.16, 1, 0.3, 1)',
        }} onClick={e => e.stopPropagation()}
      >
        <div className="mb2 display between">
          <div >
            <span className="article-viewer-title">{I18n.t('courses.article_viewer_settings.title')}</span>
          </div>

          <button
            aria-label="Close Settings Sidebar"
            className="pull-right article-viewer-button icon-close"
            onClick={toggleModal}
          />
        </div>

        <fieldset>
          <label className="display cursor-pointer mb1  font regular">
            <input
              type="radio"
              name="article-viewer-name"
              checked={articleViewerSettingsOption.showUserFullNames}
              onChange={() => setArticleViewerSettingsOption('showUserFullNames', true)}
              className="mr1 w5 h5"
            />
            {I18n.t('courses.article_viewer_settings.show_fullname')}
          </label>

          <label className="display cursor-pointer mb1 font regular">
            <input
              type="radio"
              name="article-viewer-name"
              checked={!articleViewerSettingsOption.showUserFullNames}
              onChange={() => setArticleViewerSettingsOption('showUserFullNames', false)}
              className="mr1 w5 h5"
            />
            {I18n.t('courses.article_viewer_settings.show_username')}
          </label>
        </fieldset>
      </div>
    </>
  );

  return ReactDOM.createPortal(sidebarContent, document.body);
};

export default SettingsSidebar;
