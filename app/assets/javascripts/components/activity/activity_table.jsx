import React from 'react';
import ActivityTableRow from './activity_table_row.jsx';
import TransitionGroup from 'react-addons-css-transition-group';
import Loading from '../common/loading.cjsx';
import _ from 'lodash';
import moment from 'moment';

const ActivityTable = React.createClass({
  displayName: 'ActivityTable',

  propTypes: {
    loading: React.PropTypes.bool,
    activity: React.PropTypes.array,
    headers: React.PropTypes.array,
    noActivityMessage: React.PropTypes.string
  },

  getInitialState() {
    return { activity: this.props.activity };
  },

  clearAllSortableClassNames() {
    Array.prototype.forEach.call(document.getElementsByClassName('sortable'), (el) => {
      el.classList.remove('asc');
      el.classList.remove('desc');
    });
  },

  sortItems(e) {
    const sortOrder = e.target.classList.contains('asc') ? 'desc' : 'asc';
    this.clearAllSortableClassNames();
    e.target.classList.add(sortOrder);
    const key = e.target.getAttribute('data-sort-key');
    let activities = _.sortByOrder(this.state.activity, [key]);
    if (sortOrder === 'desc') {
      activities = activities.reverse();
    }
    return this.setState(this.state.activity = activities);
  },

  render() {
    if (this.props.loading) {
      return <Loading />;
    }

    const activity = this.state.activity.map((revision) => {
      const roundedRevisionScore = Math.round(revision.revision_score) || 'unknown';
      const revisionDateTime = moment(revision.datetime).format('YYYY/MM/DD h:mm a');
      const talkPageLink = `https://en.wikipedia.org/wiki/User_talk:${revision.username}`;

      return (
        <ActivityTableRow
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
        />
      );
    });


    const drawers = this.state.activity.map((revision) => {
      const courses = revision.courses.map((course) => {
        return (
          <li key={`${revision.key}-${course.slug}`}>
            <a href={`/courses/${course.slug}`}>{course.title}</a>
          </li>
        );
      });

      return (
        <tr key={`${revision.key}-${revision.username}`} className="activity-table-drawer">
          <td colSpan="6">
            <span>
              <h5>Article is active in</h5>
              <ul className="activity-table__course-list">
                {courses}
              </ul>
            </span>
          </td>
        </tr>
      );
    });

    let elements = _.flatten(_.zip(activity, drawers));

    if (!elements.length) {
      elements = <tr><td colSpan="6">{this.props.noActivityMessage}</td></tr>;
    }

    const ths = this.props.headers.map((header) => {
      return (
        <th key={header.key} onClick={this.sortItems} className="sortable" data-sort-key={header.key}>
          {header.title}
        </th>
      );
    });

    return (
      <table className="activity-table list">
        <thead>
          <tr>
            {ths}
            <th></th>
          </tr>
        </thead>
        <TransitionGroup
          transitionName={'dyk'}
          component="tbody"
          transitionEnterTimeout={500}
          transitionLeaveTimeout={500}
        >
          {elements}
        </TransitionGroup>
      </table>
    );
  }
});

export default ActivityTable;
