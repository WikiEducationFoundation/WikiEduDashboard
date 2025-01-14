import React from 'react';
import PropTypes from 'prop-types';
import DiffViewer from '../revisions/diff_viewer.jsx';
import { toggleUI } from '../../actions';
import { useDispatch } from 'react-redux';

const ActivityTableRow = ({ isOpen, diffUrl, revisionDateTime,
  revisionScore, reportUrl, revision, rowId, articleUrl, title, talkPageLink,
  author }) => {
  const dispatch = useDispatch();

  const openDrawer = () => {
    return dispatch(toggleUI(`drawer_${rowId}`));
  };

  let revDateElement;
  let col2;
  const className = isOpen ? 'open' : 'closed';

  if (diffUrl) {
    revDateElement = (
      <a href={diffUrl} target="_blank">{revisionDateTime}</a>
    );
  }

  if (revisionScore) {
    col2 = (
      <td>
        {revisionScore}
      </td>
    );
  }

  if (reportUrl) {
    col2 = (
      <td>
        <a href={reportUrl} target="_blank">{I18n.t('recent_activity.report')}</a>
      </td>
    );
  }

  let diffViewer;
  if (revision && revision.api_url) {
    diffViewer = <DiffViewer revision={revision} />;
  }

  return (
    <tr className={className} key={rowId}>
      <td onClick={openDrawer}>
        <a href={articleUrl} target="_blank">{title}</a>
      </td>
      {col2}
      <td onClick={openDrawer}>
        <a href={talkPageLink} target="_blank">{author}</a>
      </td>
      <td onClick={openDrawer}>
        {revDateElement}
      </td>
      <td>
        {diffViewer}
      </td>
    </tr>
  );
};

ActivityTableRow.propTypes = {
  rowId: PropTypes.number,
  diffUrl: PropTypes.string,
  revisionDateTime: PropTypes.string,
  reportUrl: PropTypes.string,
  revisionScore: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.number
  ]),
  articleUrl: PropTypes.string,
  talkPageLink: PropTypes.string,
  author: PropTypes.string,
  title: PropTypes.string,
  revision: PropTypes.object,
  isOpen: PropTypes.bool,
};

export default ActivityTableRow;
