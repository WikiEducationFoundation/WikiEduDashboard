import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import RevisionList from './revision_list.jsx';
import { fetchRevisions, sortRevisions } from '../../actions/revisions_actions.js';
import Loading from '../common/loading.jsx';

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
    revisionsLoaded: PropTypes.bool,
    courseScopedRevisionsLoaded: PropTypes.bool
  },

  getInitialState() {
    return {
      isCourseScoped: false,
      isInitialFetchCourseScoped: true
    };
  },

  componentDidMount() {
    if (!this.props.revisionsLoaded) {
      // Fetching in advance initially only for all revisions
      // For Course Scoped Revisions, fetching in componentDidUpdate
      // because in most cases, users would not be using these, so we
      // will fetch only when the user initially goes there, hence saving extra queries
      this.props.fetchRevisions(this.props.course_id, this.props.limit);
    }
  },

  toggleCourseSpecific() {
    const toggledIsCourseScoped = !this.state.isCourseScoped;
    this.setState({ isCourseScoped: toggledIsCourseScoped });

    // If user reaches the course scoped part initially, and there are no
    // loaded course scoped revisions, we fetch course scoped revisions
    if (toggledIsCourseScoped && !this.props.courseScopedRevisionsLoaded) {
      this.props.fetchRevisions(this.props.course_id, this.props.courseScopedLimit, true);
    }
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

  // We disable show more button if there is a request which is still resolving
  // by keeping track of revisionsLoaded and courseScopedRevisionsLoaded
  showMore() {
    if (this.state.isCourseScoped) {
      return this.props.fetchRevisions(this.props.course_id, this.props.courseScopedLimit + 100, true);
    }
    return this.props.fetchRevisions(this.props.course_id, this.props.limit + 100);
  },

  render() {
    // Boolean to indicate whether the revisions in the current section (all scoped or course scoped are loaded)
    const loaded = (!this.state.isCourseScoped && this.props.revisionsLoaded) || (this.state.isCourseScoped && this.props.courseScopedRevisionsLoaded);
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
          loaded={loaded}
          course={this.props.course}
          sortBy={this.props.sortRevisions}
          wikidataLabels={this.props.wikidataLabels}
          sort={this.props.sort}
        />
        {!loaded && <Loading/>}
        {loaded && showMoreButton}
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
  courseScopedRevisionsLoaded: state.revisions.courseScopedRevisionsLoaded,
  revisionsLoaded: state.revisions.revisionsLoaded,
  sort: state.revisions.sort,
});

const mapDispatchToProps = {
  fetchRevisions,
  sortRevisions
};

export default connect(mapStateToProps, mapDispatchToProps)(RevisionHandler);
