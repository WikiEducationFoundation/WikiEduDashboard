import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import { chunk, forEach, get } from 'lodash-es';
import { GALLERY_VIEW } from '../../constants';
import UploadList from '../uploads/upload_list.jsx';
import { fetchUploadMetadata } from '../../actions/uploads_actions.js';

// Fetches missing thumburls and credits from the Commons API for a list of
// uploads rendered on the user profile. The course page does this through
// Redux (setUploadMetadata), but the profile page receives its uploads from
// stats.json directly, so we enrich them locally here.
const enrichUploads = async (uploads) => {
  const missing = uploads.filter(u => !u.thumburl || !u.credit);
  if (missing.length === 0) return uploads;

  const batches = chunk(missing, 25);
  const responses = await Promise.all(batches.map(fetchUploadMetadata));

  let fetchedPages = {};
  forEach(responses, (data) => {
    if (data && data.query) {
      fetchedPages = { ...fetchedPages, ...data.query.pages };
    }
  });

  return uploads.map((upload) => {
    const page = fetchedPages[upload.id];
    if (!page) return upload;
    const thumburl = upload.thumburl || get(page, 'imageinfo[0].thumburl');
    const credit = upload.credit || get(page, 'imageinfo[0].extmetadata.Credit.value', 'Not found');
    return { ...upload, thumburl, credit };
  });
};

const UserUploads = ({ uploads, username }) => {
  const [enrichedUploads, setEnrichedUploads] = useState(uploads || []);

  useEffect(() => {
    let cancelled = false;
    if (!uploads || uploads.length === 0) {
      setEnrichedUploads([]);
      return undefined;
    }
    setEnrichedUploads(uploads);
    enrichUploads(uploads)
      .then((result) => {
        if (!cancelled) setEnrichedUploads(result);
      })
      .catch(() => { /* silent: fall back to raw uploads */ });
    return () => { cancelled = true; };
  }, [uploads]);

  let uploadList = (<UploadList uploads={enrichedUploads} view={GALLERY_VIEW} />);
  if (enrichedUploads.length === 0) {
    uploadList = (<span>{I18n.t('courses.user_uploads_none')}</span>);
  }
  return (
    <div id="recent-uploads">
      <div className="user-articles__navigation">
        <Link to={`/users/${username}`} className="button ghost small">
          ← {I18n.t('users.back_to_profile') || 'Back to Profile'}
        </Link>
      </div>
      <h3>{I18n.t('courses.user_recent_uploads')}</h3>
      {uploadList}
    </div>
  );
};

UserUploads.propTypes = {
  uploads: PropTypes.array,
  username: PropTypes.string
};

export default UserUploads;