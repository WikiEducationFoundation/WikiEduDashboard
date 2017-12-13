import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import RevisionList from './revision_list.jsx';
import UIActions from '../../actions/ui_actions.js';
import ServerActions from '../../actions/server_actions.js';
import { connect } from "react-redux";
import { showMore } from '../../actions/revisions_actions.js';

const RevisionHandler = createReactClass({
  displayName: 'RevisionHandler',

  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object,
  },


  componentWillMount() {
    return ServerActions.fetchCourseRevisions(this.props.course_id, this.state.limit);
  },

  sortSelect(e) {
    return UIActions.sort('revisions', e.target.value);
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
        <div><button className="button ghost stacked right" onClick={this.props.showMore}>{I18n.t('revisions.see_more')}</button></div>
      </div>
    );
  }
}
);

const mapDispatchToProps = { showMore };

export default connect(null, mapDispatchToProps)(RevisionHandler);
