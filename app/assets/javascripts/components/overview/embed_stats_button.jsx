import React, { useState } from 'react';
import PropTypes from 'prop-types';

const EmbedStatsButton = ({ title }) => {
  const [show, setShow] = useState(false);
  const [status, setStatus] = useState('');

  const copyToClipboard = (e) => {
    const el = e.target;
    navigator.clipboard.writeText(el.value).then(() => {
      setStatus('Copied!');
    });
  };

  if (!show) {
    return (<button onClick={() => setShow(true)} className="button">{I18n.t('courses.embed_course_stats')}</button>);
  }

  const url = location.href.replace('courses', 'embed/course_stats');

  return (
    <div className="basic-modal course-stats-download-modal embed_stats">
      <button onClick={() => setShow(false)} className="pull-right article-viewer-button icon-close" />
      <h4>{I18n.t('courses.embed_course_stats_description')} <code>&lt;body&gt;</code></h4>
      <textarea
        id="embed"
        readOnly
        value={
          `<a href="${location.href}">${title}</a><!-- This is optional -->
<iframe src="${url}" style="width:100%;border:0px none transparent;"></iframe>`}
        onClick={copyToClipboard}
      />
      <small>{status}</small>
    </div>
  );
};

EmbedStatsButton.propTypes = {
  title: PropTypes.string
};

export default EmbedStatsButton;
