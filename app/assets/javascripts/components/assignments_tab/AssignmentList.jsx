import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import { useSearchParams } from 'react-router-dom';
import AssignmentDrawer from './AssignmentDrawer';
import { formatDate, itemTitle, kindLabel, stateLabel } from './assignmentHelpers';

// Every other tracked assignment (the assigned article has its own panel), in
// timeline order, with how many students are where on it. Clicking a row opens
// it as an accordion: the drawer below lists every student's status and work
// on that assignment. One row is open at a time, kept in the URL (?open=<key>)
// so it can be linked and returned to.
const STATES = ['complete', 'in_progress', 'not_started'];

// Which segment is which, once, in the column heading.
const StateLegend = () => (
  <span className="assignments-tab__legend">
    {STATES.map(state => (
      <span key={state} className="assignments-tab__legend-item">
        <span className={`assignments-tab__swatch assignments-tab__segment--${state}`} aria-hidden="true" />
        {stateLabel(state)}
      </span>
    ))}
  </span>
);

// Where the class is on one assignment: a single bar split into completed, in
// progress and not started (one hue, darkest for completed), with the counts
// written out beneath so nothing rests on color.
const StateBar = ({ summary }) => {
  const segments = STATES.filter(state => summary[state] > 0);
  return (
    <div className="assignments-tab__state">
      <div className="assignments-tab__state-bar" aria-hidden="true">
        {segments.map(state => (
          <span
            key={state} className={`assignments-tab__segment assignments-tab__segment--${state}`}
            style={{ flexGrow: summary[state] }}
            title={`${stateLabel(state)}: ${summary[state]} / ${summary.total}`}
          />
        ))}
      </div>
      <div className="assignments-tab__state-counts">
        {segments.map(state => `${summary[state]} ${stateLabel(state)}`).join(' · ')}
      </div>
    </div>
  );
};

StateBar.propTypes = { summary: PropTypes.object.isRequired };

const AssignmentList = ({ data, itemData, loadItem, tabPath }) => {
  const [searchParams, setSearchParams] = useSearchParams();
  const openKey = searchParams.get('open');
  const summaryByKey = Object.fromEntries(data.summary.map(row => [row.key, row]));
  const items = data.items.filter(item => item.kind !== 'article');

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
          <th className="assignments-tab__progress-heading">
            {I18n.t('assignments_tab.progress')}
            <StateLegend />
          </th>
          <th>{I18n.t('assignments_tab.overdue')}</th>
          <th />
        </tr>
      </thead>
      <tbody>
        {items.map((item) => {
          const summary = summaryByKey[item.key];
          const isOpen = openKey === item.key;
          return (
            <Fragment key={item.key}>
              <tr className={isOpen ? 'open' : ''} onClick={() => toggle(item.key)}>
                <td>
                  {itemTitle(item)}
                  <span className="assignments-tab__kind">{kindLabel(item)}</span>
                </td>
                <td>{formatDate(item.due_date)}</td>
                <td><StateBar summary={summary} /></td>
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
  itemData: PropTypes.object.isRequired,
  loadItem: PropTypes.func.isRequired,
  data: PropTypes.shape({ items: PropTypes.array, summary: PropTypes.array }).isRequired,
  tabPath: PropTypes.string.isRequired,
};

export default AssignmentList;
