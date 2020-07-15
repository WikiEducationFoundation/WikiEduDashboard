import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import RevisionList from './revision_list.jsx';
import { fetchRevisions, sortRevisions } from '../../actions/revisions_actions.js';

const RevisionHandler = createReactClass({
  displayName: 'RevisionHandler',

  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object,
    courseScopedLimit: PropTypes.number,
    courseScopedLimitReached: PropTypes.bool,
    courseSpecificRevisions: PropTypes.array,
    fetchRevisions: PropTypes.func,
    limit: PropTypes.number,
    limitReached: PropTypes.bool,
    revisions: PropTypes.array,
    wikidataLabels: PropTypes.object,
    loadingRevisions: PropTypes.bool
  },

  getInitialState() {
    return {
      isCourseScoped: false,
      isInitialFetchCourseScoped: true
    };
  },

  componentDidMount() {
    if (this.props.loadingRevisions) {
      // Fetching in advance initially only for all revisions
      // For Course Scoped Revisions, fetching in componentDidUpdate
      // because in most cases, users would not be using these, so we
      // will fetch only when the user initially goes there, hence saving extra queries
      this.props.fetchRevisions(this.props.course_id, this.props.limit);
    }
  },

  componentDidUpdate() {
    // This block of code runs only once, when the user initially goes to the course scoped part
    if (this.state.isCourseScoped && this.state.isInitialFetchCourseScoped) {
      this.props.fetchRevisions(this.props.course_id, this.props.courseScopedLimit, true);
      // eslint-disable-next-line react/no-did-update-set-state
      this.setState({ isInitialFetchCourseScoped: false });
    }
  },

  toggleCourseSpecific() {
    this.setState({ isCourseScoped: !this.state.isCourseScoped });
  },

  revisionFilterButtonText() {
    if (this.state.isCourseScoped) {
      return I18n.t('revisions.show_all');
    }
    return I18n.t('revisions.show_course_specific');
  },

  sortSelect(e) {
    return this.props.sortRevisions(e.target.value);
  },

  showMore() {
    if (this.state.isCourseScoped) {
      return this.props.fetchRevisions(this.props.course_id, this.props.courseScopedLimit + 100, true);
    }
    return this.props.fetchRevisions(this.props.course_id, this.props.limit + 100);
  },

  render() {
    const revisions = this.state.isCourseScoped ? this.props.courseScopedRevisions : this.props.revisions;

    let showMoreButton;
    if ((!this.state.isCourseScoped && !this.props.limitReached) || (this.state.isCourseScoped && !this.props.courseScopedLimitReached)) {
      showMoreButton = <div><button className="button ghost stacked right" onClick={this.showMore}>{I18n.t('revisions.see_more')}</button></div>;
    }
    const revisionFilterButton = <div><button className="button ghost stacked right" onClick={this.toggleCourseSpecific}>{this.revisionFilterButtonText()}</button></div>;
    return (
      <div id="revisions">
        <div className="section-header">
          <h3>{I18n.t('application.recent_activity')}</h3>
          {revisionFilterButton}
          <div className="sort-select">
            <select className="sorts" name="sorts" onChange={this.sortSelect}>
              <option value="rating_num">{I18n.t('revisions.class')}</option>
              <option value="title">{I18n.t('revisions.title')}</option>
              <option value="revisor">{I18n.t('revisions.edited_by')}</option>
              <option value="characters">{I18n.t('revisions.chars_added')}</option>
              <option value="references">{I18n.t('revisions.references')}</option>
              <option value="date">{I18n.t('revisions.date_time')}</option>
            </select>
          </div>
        </div>
        <RevisionList
          revisions={revisions}
          course={this.props.course}
          sortBy={this.props.sortRevisions}
          wikidataLabels={this.props.wikidataLabels}
          sort={this.props.sort}
        />
        {showMoreButton}
      </div>
    );
  }
});

const mapStateToProps = state => ({
  courseScopedLimit: state.revisions.courseScopedLimit,
  courseScopedLimitReached: state.revisions.courseScopedLimitReached,
  courseScopedRevisions: state.revisions.courseScopedRevisions,
  limit: state.revisions.limit,
  limitReached: state.revisions.limitReached,
  revisions: state.revisions.revisions,
  wikidataLabels: state.wikidataLabels.labels,
  loadingRevisions: state.revisions.loading,
  sort: state.revisions.sort,
});

const mapDispatchToProps = {
  fetchRevisions,
  sortRevisions
};

export default connect(mapStateToProps, mapDispatchToProps)(RevisionHandler);
