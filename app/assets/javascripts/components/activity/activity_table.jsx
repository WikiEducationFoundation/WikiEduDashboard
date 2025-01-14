import React from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import { flatten, zip } from 'lodash-es';
import { formatDateWithTime } from '../../utils/date_utils';
import ActivityTableRow from './activity_table_row.jsx';
import Loading from '../common/loading.jsx';

const ActivityTable = ({ onSort, activity, headers, loading, noActivityMessage }) => {
  const openKey = useSelector(state => state.ui.openKey);

  const sortItems = (e) => {
    onSort(e.currentTarget.getAttribute('data-sort-key'));
  };

  const _renderActivites = () => {
    return activity.map((revision) => {
      const roundedRevisionScore = Math.round(revision.revision_score) || 'unknown';
      const revisionDateTime = formatDateWithTime(revision.datetime);
      const talkPageLink = `${revision.base_url}/wiki/User_talk:${revision.username}`;
      const isOpen = openKey === `drawer_${revision.key}`;

      return (
        <ActivityTableRow
          revision={revision}
          key={revision.key}
          rowId={revision.key}
          articleUrl={revision.article_url}
          diffUrl={revision.diff_url}
          talkPageLink={talkPageLink}
          reportUrl={revision.report_url}
          title={revision.title}
          revisionScore={roundedRevisionScore}
          author={revision.username}
          revisionDateTime={revisionDateTime}
          isOpen={isOpen}
        />
      );
    });
  };

  const _renderDrawers = () => {
    return activity.map((revision) => {
      const courses = revision.courses.map((course) => {
        return (
          <li key={`${revision.key}-${course.slug}`}>
            <a href={`/courses/${course.slug}`}>{course.title}</a>
          </li>
        );
      });

      return (
        <tr key={`${revision.key}-${revision.username}`} className="activity-table-drawer drawer">
          <td colSpan="5">
            <span />
            <table className="table">
              <tbody>
                <tr>
                  <td>
                    <span>
                      <h5>{I18n.t('recent_activity.active_courses')}</h5>
                      <ul className="activity-table__course-list">
                        {courses}
                      </ul>
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </td>
        </tr>
      );
    });
  };

  const _renderHeaders = () => {
    return headers.map((header) => {
      return (
        <th style={header.style || {}} key={header.key} onClick={sortItems} className="sortable asc" data-sort-key={header.key}>
          {header.title}
          <span className="sortable-indicator" />
        </th>
      );
    });
  };

  if (loading) {
    return <Loading />;
  }

  const renderedActivity = _renderActivites();
  const drawers = _renderDrawers();
  const ths = _renderHeaders();

  let elements = flatten(zip(renderedActivity, drawers));
  if (!elements.length) {
    elements = <tr><td colSpan={headers.length + 1}>{noActivityMessage}</td></tr>;
  }

  return (
    <table className="table table--expandable table--hoverable table--clickable table--sortable activity-table">
      <thead>
        <tr>
          {ths}
          <th />
        </tr>
      </thead>
      <tbody>
        {elements}
      </tbody>
    </table>
  );
};

ActivityTable.propTypes = {
  loading: PropTypes.bool,
  activity: PropTypes.array,
  headers: PropTypes.array,
  noActivityMessage: PropTypes.string,
  toggleDrawer: PropTypes.func
};

export default (ActivityTable);
