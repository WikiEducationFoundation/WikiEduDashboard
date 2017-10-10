import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import moment from 'moment';

import * as UIActions from '../../actions';
import ActivityTableRow from './activity_table_row.jsx';
import Loading from '../common/loading.jsx';


const ActivityTable = createReactClass({
  displayName: 'ActivityTable',

  propTypes: {
    loading: PropTypes.bool,
    activity: PropTypes.array,
    headers: PropTypes.array,
    noActivityMessage: PropTypes.string,
    openKey: PropTypes.string,
    toggleDrawer: PropTypes.func
  },

  getInitialState() {
    return {
      activity: this.props.activity
    };
  },

  componentWillReceiveProps(nextProps) {
    if (nextProps.activity !== this.state.activity) {
      this.setState({ activity: nextProps.activity });
    }
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
      const talkPageLink = `${revision.base_url}/wiki/User_talk:${revision.username}`;
      const isOpen = this.props.openKey === `drawer_${revision.key}`;

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
          toggleDrawer={this.props.toggleDrawer}
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
        <tr key={`${revision.key}-${revision.username}`} className="activity-table-drawer drawer">
          <td colSpan="5">
            <span />
            <table className="table">
              <tbody>
                <tr><td>
                  <span>
                    <h5>{I18n.t('recent_activity.active_courses')}</h5>
                    <ul className="activity-table__course-list">
                      {courses}
                    </ul>
                  </span>
                </td></tr>
              </tbody>
            </table>
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
          <span className="sortable-indicator" />
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
            <th />
          </tr>
        </thead>
        <tbody>
          {elements}
        </tbody>
      </table>
    );
  }
});

const mapStateToProps = state => ({
  openKey: state.ui.openKey
});

const mapDispatchToProps = dispatch => ({
  toggleDrawer: bindActionCreators(UIActions, dispatch).toggleUI
});

export default connect(mapStateToProps, mapDispatchToProps)(ActivityTable);
