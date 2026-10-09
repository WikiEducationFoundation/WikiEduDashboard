import React from 'react';

// Renders the message the same way app/views/shared/_flash.html.haml does —
// as raw HTML inside the banner's own classes — so the preview matches what
// visitors will see, including link colors and collapsed whitespace.
const SiteNoticePreview = ({ message }) => {
  const hasMessage = !!message && message.trim().length > 0;

  return (
    <div className="site-notice-preview">
      <div className="site-notice-preview__heading">
        {I18n.t('settings.common_settings_components.headings.site_notice_preview')}
      </div>

      {hasMessage ? (
        <div
          className="notification sitenotice"
          dangerouslySetInnerHTML={{ __html: message }}
        />
      ) : (
        <div className="site-notice-preview__empty">
          Type a message to see the preview.
        </div>
      )}
    </div>
  );
};

export default SiteNoticePreview;
