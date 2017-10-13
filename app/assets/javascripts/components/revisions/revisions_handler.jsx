import React from 'react';
import RevisionList from './revision_list.jsx';
import UIActions from '../../actions/ui_actions.js';
import ServerActions from '../../actions/server_actions.js';

const RevisionHandler = React.createClass({
  displayName: 'RevisionHandler',

  propTypes: {
    course_id: React.PropTypes.string,
    course: React.PropTypes.object,
  },

  getInitialState() {
    return {
      limit: 50
    };
  },

  componentWillMount() {
    return ServerActions.fetchCourseRevisions(this.props.course_id, this.state.limit);
  },

  sortSelect(e) {
    return UIActions.sort('revisions', e.target.value);
  },

  showMore() {
    const newLimit = this.state.limit + 100;
    this.setState({ limit: newLimit });
    return ServerActions.fetchCourseRevisions(this.props.course_id, newLimit);
  },

  render() {
    return (
      <div id="revisions">
        <div className="section-header">
          <h3>{I18n.t('activity.label')}</h3>
          <div className="sort-select">
            <select className="sorts" name="sorts" onChange={this.sortSelect}>
              <option value="rating_num">{I18n.t('revisions.class')}</option>
              <option value="title">{I18n.t('revisions.title')}</option>
              <option value="edited_by">{I18n.t('revisions.edited_by')}</option>
              <option value="characters">{I18n.t('revisions.chars_added')}</option>
              <option value="date">{I18n.t('revisions.date_time')}</option>
            </select>
          </div>
        </div>
        <RevisionList course={this.props.course} />
        <div><button className="button ghost stacked right" onClick={this.showMore}>{I18n.t('revisions.see_more')}</button></div>
      </div>
    );
  }
}
);

export default RevisionHandler;
