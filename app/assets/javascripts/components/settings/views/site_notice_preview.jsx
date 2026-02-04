import React from 'react';

const SiteNoticePreview = ({ message, enabled }) => {
    const hasMessage = !!message && message.trim().length > 0;

    return (
      <div style={{ marginTop: 10 }}>
        <div style={{ fontSize: 12, opacity: 0.8, marginBottom: 6 }}>
          {I18n.t('settings.common_settings_components.headings.site_notice_preview')}
        </div>

        {enabled && hasMessage ? (
          <div
            style={{
            border: '1px solid #ddd',
            padding: '10px 12px',
            borderRadius: 4,
            whiteSpace: 'pre-wrap',
            wordBreak: 'break-word',
          }}
          >
            {message}
          </div>
      ) : (
        <div style={{ fontSize: 12, opacity: 0.7 }}>
          {!enabled
            ? 'Preview is hidden because the notice is disabled.'
            : 'Type a message to see the preview.'}
        </div>
      )}
      </div>
    );
};

export default SiteNoticePreview;
