import React from 'react';
import ActivityTableRow from './activity_table_row.jsx';
import Loading from '../common/loading.jsx';
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
    return {
      activity: this.props.activity
    };
  },

  clearAllSortableClassNames() {
    Array.prototype.forEach.call(document.getElementsByClassName('sortable'), (el) => {
      el.classList.remove('asc');
      el.classList.remove('desc');
    });
  },

  sortItems(e) {
    this.clearAllSortableClassNames();

    const nextSortOrder = e.target.classList.contains('asc') ? 'desc' : 'asc';
    e.target.classList.add(nextSortOrder);

    const key = e.target.getAttribute('data-sort-key');
    let activities = _.sortByOrder(this.state.activity, [key]);
    if (nextSortOrder === 'desc') {
      activities = activities.reverse();
    }

    this.setState({
      activity: activities
    });
  },

  _renderActivites() {
    return this.state.activity.map((revision) => {
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
  },

  _renderDrawers() {
    return this.state.activity.map((revision) => {
      const courses = revision.courses.map((course) => {
        return (
          <li key={`${revision.key}-${course.slug}`}>
            <a href={`/courses/${course.slug}`}>{course.title}</a>
          </li>
        );
      });

      return (
        <tr key={`${revision.key}-${revision.username}`} className="activity-table-drawer">
          <td colSpan="5">
            <span>
              <h5>{I18n.t('recent_activity.active_courses')}</h5>
              <ul className="activity-table__course-list">
                {courses}
              </ul>
            </span>
          </td>
        </tr>
      );
    });
  },

  _renderHeaders() {
    return this.props.headers.map((header) => {
      return (
        <th style={header.style || {}} key={header.key} onClick={this.sortItems} className="sortable" data-sort-key={header.key}>
          {header.title}
          <span className="sortable-indicator"></span>
        </th>
      );
    });
  },

  render() {
    if (this.props.loading) {
      return <Loading />;
    }

    const activity = this._renderActivites();
    const drawers = this._renderDrawers();
    const ths = this._renderHeaders();

    let elements = _.flatten(_.zip(activity, drawers));
    if (!elements.length) {
      elements = <tr><td colSpan={this.props.headers.length + 1}>{this.props.noActivityMessage}</td></tr>;
    }

    return (
      <table className="table table--expandable table--hoverable table--clickable table--sortable activity-table">
        <thead>
          <tr>
            {ths}
            <th></th>
          </tr>
        </thead>
        <tbody>
          {elements}
        </tbody>
      </table>
    );
  }
});

export default ActivityTable;
