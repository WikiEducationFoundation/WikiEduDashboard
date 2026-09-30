import React, { Fragment, useState } from 'react';
import PropTypes from 'prop-types';
import { useSearchParams } from 'react-router-dom';
import AssignmentDrawer from './AssignmentDrawer';
import { fetchAssignmentProgress } from './AssignmentProgressAPI';
import { formatDate, itemTitle, kindLabel, stateLabel } from './assignmentHelpers';

// The assigned article is the heart of the course, so its row stands out.
const rowClassName = (item, isOpen) => [
  isOpen ? 'open' : '',
  item.kind === 'article' ? 'assignments-tab__row--article' : '',
].filter(Boolean).join(' ');

// Every tracked assignment, in timeline order, with how many students are
// where on it. Clicking a row opens it as an accordion: the drawer below lists
// every student's status and work on that assignment. One row is open at a
// time, kept in the URL (?open=<key>) so it can be linked and returned to.
const AssignmentList = ({ courseSlug, data, tabPath }) => {
  const [searchParams, setSearchParams] = useSearchParams();
  const openKey = searchParams.get('open');
  const [itemData, setItemData] = useState({});
  const summaryByKey = Object.fromEntries(data.summary.map(row => [row.key, row]));

  const loadItem = (key) => {
    fetchAssignmentProgress(courseSlug, key)
      .then(result => setItemData(loaded => ({ ...loaded, [key]: result })))
      .catch(() => setItemData(loaded => ({ ...loaded, [key]: { failed: true } })));
  };

  // A status filter belongs to the row it was set on, so switching rows drops it.
  const toggle = (key) => {
    setSearchParams(openKey === key ? {} : { open: key }, { replace: true });
  };

  return (
    <table className="table table--hoverable table--expandable assignments-tab__list">
      <thead>
        <tr>
          <th>{I18n.t('timeline.block_assignment')}</th>
          <th>{I18n.t('lti.assignment_view.trainings.due_date')}</th>
          <th>{stateLabel('complete')}</th>
          <th>{stateLabel('in_progress')}</th>
          <th>{stateLabel('not_started')}</th>
          <th>{I18n.t('assignments_tab.overdue')}</th>
          <th />
        </tr>
      </thead>
      <tbody>
        {data.items.map((item) => {
          const summary = summaryByKey[item.key];
          const isOpen = openKey === item.key;
          return (
            <Fragment key={item.key}>
              <tr className={rowClassName(item, isOpen)} onClick={() => toggle(item.key)}>
                <td>
                  {itemTitle(item)}
                  {item.kind !== 'article' && <span className="assignments-tab__kind">{kindLabel(item)}</span>}
                </td>
                <td>{formatDate(item.due_date)}</td>
                <td>{summary.complete}</td>
                <td>{summary.in_progress}</td>
                <td>{summary.not_started}</td>
                <td className={summary.overdue ? 'assignments-tab__overdue-count' : ''}>
                  {summary.overdue || null}
                </td>
                <td>
                  <button
                    className="icon icon-arrow-toggle table-expandable-indicator"
                    aria-expanded={isOpen}
                    aria-controls={`assignment-drawer-${item.key}`}
                    aria-label={itemTitle(item)}
                    onClick={(event) => { event.stopPropagation(); toggle(item.key); }}
                  />
                </td>
              </tr>
              {isOpen && (
                <AssignmentDrawer
                  item={item} itemData={itemData[item.key]} loadItem={loadItem} tabPath={tabPath}
                />
              )}
            </Fragment>
          );
        })}
      </tbody>
    </table>
  );
};

AssignmentList.propTypes = {
  courseSlug: PropTypes.string.isRequired,
  data: PropTypes.shape({ items: PropTypes.array, summary: PropTypes.array }).isRequired,
  tabPath: PropTypes.string.isRequired,
};

export default AssignmentList;
