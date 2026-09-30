import React, { useId, useState } from 'react';
import PropTypes from 'prop-types';
import { fetchPagePreview } from './sandboxPreview';

// A Show/Hide toggle that loads a sandbox (or any wiki page) inline, the first
// time it's opened. A failed or missing page is retried on the next open, in
// case the student has created it since.
const SandboxPreview = ({ url }) => {
  const [open, setOpen] = useState(false);
  const [preview, setPreview] = useState({ status: 'idle' });
  const panelId = useId();

  const toggle = () => {
    setOpen(!open);
    if (open || preview.status === 'loaded' || preview.status === 'loading') { return; }
    setPreview({ status: 'loading' });
    fetchPagePreview(url)
      .then(html => setPreview(html ? { status: 'loaded', html } : { status: 'not_found' }))
      .catch(() => setPreview({ status: 'error' }));
  };

  let content;
  if (preview.status === 'loaded') {
    // MediaWiki's parser output, as the article viewer also renders it.
    content = <div className="assignments-tab__preview-content" dangerouslySetInnerHTML={{ __html: preview.html }} />;
  } else if (preview.status !== 'idle') {
    content = <p>{I18n.t(`lti.assignment_view.sandbox_preview.${preview.status}`)}</p>;
  }

  return (
    <>
      <button
        type="button" className="button border small" aria-expanded={open}
        aria-controls={panelId} onClick={toggle}
      >
        {I18n.t(open ? 'lti.assignment_view.hide' : 'lti.assignment_view.show')}
      </button>
      <div id={panelId} className="assignments-tab__preview-panel" hidden={!open}>{content}</div>
    </>
  );
};

SandboxPreview.propTypes = { url: PropTypes.string.isRequired };

export default SandboxPreview;
