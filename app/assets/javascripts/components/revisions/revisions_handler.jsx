import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import RevisionList from './revision_list.jsx';
import { connect } from "react-redux";
import { fetchRevisions, sortRevisions } from "../../actions/revisions_actions.js";

const RevisionHandler = createReactClass({
  displayName: 'RevisionHandler',

  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object,
    fetchRevisions: PropTypes.func,
    limitReached: PropTypes.bool,
    limit: PropTypes.number,
    revisions: PropTypes.array
  },

  componentWillMount() {
    return this.props.fetchRevisions(this.props.course_id, this.props.limit);
  },

  sortSelect(e) {
    return this.props.sortRevisions(e.target.value);
  },

  showMore() {
    return this.props.fetchRevisions(this.props.course_id, this.props.limit + 100);
  },

  render() {
    let showMoreButton;
    if (!this.props.limitReached) {
      showMoreButton = <div><button className="button ghost stacked right" onClick={this.showMore}>{I18n.t('revisions.see_more')}</button></div>;
    }
    return (
      <div id="revisions">
        <div className="section-header">
          <h3>{I18n.t('activity.label')}</h3>
          <div className="sort-select">
            <select className="sorts" name="sorts" onChange={this.sortSelect}>
              <option value="rating_num">{I18n.t('revisions.class')}</option>
              <option value="title">{I18n.t('revisions.title')}</option>
              <option value="revisor">{I18n.t('revisions.edited_by')}</option>
              <option value="characters">{I18n.t('revisions.chars_added')}</option>
              <option value="date">{I18n.t('revisions.date_time')}</option>
            </select>
          </div>
        </div>
        <RevisionList revisions={this.props.revisions} course={this.props.course} sortBy={this.props.sortRevisions} />
        {showMoreButton}
      </div>
    );
  }
});

const mapStateToProps = state => ({
  limit: state.revisions.limit,
  revisions: state.revisions.revisions,
  limitReached: state.revisions.limitReached
});

const mapDispatchToProps = {
  fetchRevisions,
  sortRevisions
};

export default connect(mapStateToProps, mapDispatchToProps)(RevisionHandler);
