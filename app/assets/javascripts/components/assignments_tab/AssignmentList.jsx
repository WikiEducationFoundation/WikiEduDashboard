import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import { useSearchParams } from 'react-router-dom';
import AssignmentDrawer from './AssignmentDrawer';
import { formatDate, itemTitle, kindLabel, stateLabel } from './assignmentHelpers';

// Every other tracked assignment (the assigned article has its own panel), a
// table per kind, each in timeline order, with how many students are where on
// it. Clicking a row opens it as an accordion: the drawer below lists every
// student's status and work on that assignment. One row is open at a time,
// across the tables, kept in the URL (?open=<key>) so it can be linked and
// returned to.
const STATES = ['complete', 'in_progress', 'not_started'];

const SECTIONS = [
  { kind: 'training', heading: 'lti.student_overview.trainings' },
  { kind: 'exercise', heading: 'lti.student_overview.exercises' },
  { kind: 'peer_review', heading: 'lti.status.roster.peer_reviews' },
];

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

// One kind's assignments, named by the section heading above it.
const AssignmentTable = ({ items, headingId, summaryByKey, openKey, toggle, itemData, loadItem, tabPath }) => (
  <table
    className="table table--hoverable table--expandable assignments-tab__list" aria-labelledby={headingId}
  >
    <thead>
      <tr>
        <th>{kindLabel(items[0])}</th>
        <th className="assignments-tab__due-heading">{I18n.t('lti.assignment_view.trainings.due_date')}</th>
        <th className="assignments-tab__progress-heading">
          {I18n.t('assignments_tab.progress')}
          <StateLegend />
        </th>
        <th className="assignments-tab__overdue-heading">{I18n.t('assignments_tab.overdue')}</th>
        <th className="assignments-tab__toggle-heading" />
      </tr>
    </thead>
    <tbody>
      {items.map((item) => {
        const summary = summaryByKey[item.key];
        const isOpen = openKey === item.key;
        return (
          <Fragment key={item.key}>
            <tr className={isOpen ? 'open' : ''} onClick={() => toggle(item.key)}>
              <td>{itemTitle(item)}</td>
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

AssignmentTable.propTypes = {
  items: PropTypes.array.isRequired,
  headingId: PropTypes.string.isRequired,
  summaryByKey: PropTypes.object.isRequired,
  openKey: PropTypes.string,
  toggle: PropTypes.func.isRequired,
  itemData: PropTypes.object.isRequired,
  loadItem: PropTypes.func.isRequired,
  tabPath: PropTypes.string.isRequired,
};

const AssignmentList = ({ data, itemData, loadItem, tabPath }) => {
  const [searchParams, setSearchParams] = useSearchParams();
  const openKey = searchParams.get('open');
  const summaryByKey = Object.fromEntries(data.summary.map(row => [row.key, row]));

  // A status filter belongs to the row it was set on, so switching rows drops
  // it; the student sort is kept.
  const toggle = (key) => {
    const params = openKey === key ? {} : { open: key };
    if (searchParams.get('sort')) { params.sort = searchParams.get('sort'); }
    setSearchParams(params, { replace: true });
  };

  return SECTIONS.map(({ kind, heading }) => {
    const items = data.items.filter(item => item.kind === kind);
    if (!items.length) { return null; }
    const headingId = `assignments-tab-${kind}-heading`;
    return (
      <section key={kind} className="assignments-tab__section">
        <h3 id={headingId}>{I18n.t(heading)}</h3>
        <AssignmentTable
          items={items} headingId={headingId} summaryByKey={summaryByKey} openKey={openKey}
          toggle={toggle} itemData={itemData} loadItem={loadItem} tabPath={tabPath}
        />
      </section>
    );
  });
};

AssignmentList.propTypes = {
  itemData: PropTypes.object.isRequired,
  loadItem: PropTypes.func.isRequired,
  data: PropTypes.shape({ items: PropTypes.array, summary: PropTypes.array }).isRequired,
  tabPath: PropTypes.string.isRequired,
};

export default AssignmentList;
