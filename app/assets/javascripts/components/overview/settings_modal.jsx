
import React from 'react';

const SettingsModal = (props) => {
  return (
    <div className="modal-container">
      <div className="modal" >
        <div style={{ marginBottom: '20px' }}>
          <span className="article-viewer-title">{I18n.t('courses.article_viewer_settings.title')}</span>
        </div>

        <div className="check-container">
          <span>{I18n.t('courses.article_viewer_settings.show_fullname')}</span>
          <input
            type="checkbox"
            checked={props.articleViewerSettingsOption.showUserFullNames}
            onChange={() => props.setArticleViewerSettingsOption(
              'showUserFullNames', !props.articleViewerSettingsOption.showUserFullNames)}
          />
        </div>
        <hr />
        <button className="button dark" onClick={props.toggleModal}>
          {I18n.t('metrics.close_modal')}
        </button>
      </div>
    </div>
  );
};
export default SettingsModal;
