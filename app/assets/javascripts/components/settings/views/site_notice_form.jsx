import React, { useState } from 'react';
import TextInput from '../../common/text_input';
import { useDispatch } from 'react-redux';

const SiteNoticeForm = (props) => {
  const [siteNotice, setSiteNotice] = useState();
  const dispatch = useDispatch();

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
          <TextInput
            id="site_notice"
            editable
            onChange={handleChange}
            value={siteNotice}
            value_key="site_notice"
            type="text"
            label="Site Notice"
            maxLength="255"
          />
          <button className="button border" type="submit" value="Submit">{I18n.t('application.submit')}</button>
        </form>
      </td>
    </tr>
  );
};

export default SiteNoticeForm;
