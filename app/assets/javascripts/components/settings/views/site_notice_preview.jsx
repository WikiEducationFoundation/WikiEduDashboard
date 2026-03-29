import React from 'react';

const SiteNoticePreview = ({ message, enabled }) => {
    const hasMessage = !!message && message.trim().length > 0;

    return (
      <div style={{ marginTop: 10, marginBottom: 10, width: '100%', maxWidth: '100%', boxSizing: 'border-box' }}>
        <div style={{ fontSize: 12, opacity: 0.8, marginBottom: 6 }}>
          {I18n.t('settings.common_settings_components.headings.site_notice_preview')}
        </div>

        {enabled && hasMessage ? (
          <div
            className="site-notice__preview-body"
            style={{
            border: '2px solid #676eb4', // use dashboard purple for emphasis
            backgroundColor: '#f8f9fa',
            padding: '12px 14px',
            borderRadius: 4,
            whiteSpace: 'pre-wrap',
            overflowWrap: 'anywhere',
            wordBreak: 'break-all',
            width: '100%',
            maxWidth: '100%',
            boxSizing: 'border-box'
          }}
          >
            {message}
          </div>
      ) : (
        <div style={{ fontSize: 13, color: '#72777d', fontStyle: 'italic' }}>
          {!enabled
            ? I18n.t('settings.common_settings_components.headings.site_notice_preview_hidden')
            : I18n.t('settings.common_settings_components.headings.site_notice_preview_empty')}
        </div>
      )}
      </div>
    );
};

export default SiteNoticePreview;
