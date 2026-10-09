import React, { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { useDispatch } from 'react-redux';
import SiteNoticePreview from './site_notice_preview';

const SiteNoticeForm = (props) => {
  const [siteNotice, setSiteNotice] = useState(props.currentSiteNotice?.message || '');
  const textareaRef = useRef(null);
  const dispatch = useDispatch();

  useEffect(() => {
    setSiteNotice(props.currentSiteNotice?.message || '');
  }, [props.currentSiteNotice]);

  // Grow the textarea to fit its content, so the whole notice is always visible.
  // The popover keeps the form mounted while hidden, where scrollHeight is 0,
  // so measure again each time it opens.
  useLayoutEffect(() => {
    const textarea = textareaRef.current;
    if (!textarea || !props.isOpen) { return; }
    textarea.style.height = 'auto';
    textarea.style.height = `${textarea.scrollHeight + 2}px`;
  }, [siteNotice, props.isOpen]);

  const handleSubmit = (e) => {
    e.preventDefault();
    dispatch(props.updateSiteNotice({ message: siteNotice, status: props.currentStatus }));
    props.handlePopoverClose(e);
  };

  return (
    <tr>
      <td>
        <form className="site-notice-form" onSubmit={handleSubmit}>
          <label htmlFor="site_notice">
            {I18n.t('settings.common_settings_components.headings.site_notice_message')}
          </label>
          <textarea
            id="site_notice"
            ref={textareaRef}
            value={siteNotice}
            onChange={e => setSiteNotice(e.target.value)}
            placeholder="Enter site notice"
            rows="4"
          />
          <div className="site-notice-form__help">
            <p>{I18n.t('settings.common_settings_components.site_notice_help.intro')}</p>
            <ul>
              <li>
                {I18n.t('settings.common_settings_components.site_notice_help.link')}:{' '}
                <code>{'<a href="https://example.org">link text</a>'}</code>
              </li>
              <li>
                {I18n.t('settings.common_settings_components.site_notice_help.line_break')}:{' '}
                <code>{'<br>'}</code>
              </li>
            </ul>
          </div>

          <SiteNoticePreview message={siteNotice} />
          <button className="button border" type="submit" value="Submit">{I18n.t('application.submit')}</button>
        </form>
      </td>
    </tr>
  );
};

export default SiteNoticeForm;
