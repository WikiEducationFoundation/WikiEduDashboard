import React, { useEffect, useState } from 'react';
import { useDispatch } from 'react-redux';
import SiteNoticePreview from './site_notice_preview';
import TextAreaInput from '../../common/text_area_input';

const SiteNoticeForm = (props) => {
  const [siteNotice, setSiteNotice] = useState(props.currentSiteNotice?.message || '');
  const dispatch = useDispatch();

  useEffect(() => {
    setSiteNotice(props.currentSiteNotice?.message || '');
  }, [props.currentSiteNotice]);

  const handleChange = (key, value) => {
    setSiteNotice(value);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    dispatch(props.updateSiteNotice({ message: siteNotice, status: props.currentStatus }));
    props.handlePopoverClose(e);
  };

  return (
    <tr>
      <td>
        <form onSubmit={handleSubmit}>
          <TextAreaInput
            id="site_notice"
            editable={true}
            value={siteNotice}
            onChange={handleChange}
            placeholder="Enter site notice"
            autoExpand={true}
            rows="1"
            wysiwyg={false}
            value_key="site_notice"
            maxLength="255"
          />

          <SiteNoticePreview
            message={siteNotice}
            enabled={!!props.currentStatus}
          />
          <button className="button border" type="submit" value="Submit">{I18n.t('application.submit')}</button>
        </form>
      </td>
    </tr>
  );
};

export default SiteNoticeForm;
