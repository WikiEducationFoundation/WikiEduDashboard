import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import RevisionList from './revision_list.jsx';
import { fetchRevisions, sortRevisions, fetchCourseScopedRevisions } from '../../actions/revisions_actions.js';
import Loading from '../common/loading.jsx';
import ProgressIndicator from '../common/progress_indicator.jsx';
import { ARTICLE_FETCH_LIMIT } from '../../constants/revisions.js';
import Select from 'react-select';
import sortSelectStyles from '../../styles/sort_select';

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
    // sets the title of this tab
    document.title = `${this.props.course.title} - ${I18n.t('application.recent_activity')}`;

    if (!this.props.revisionsLoaded) {
      // Fetching in advance initially only for all revisions
      // For Course Scoped Revisions, fetching in componentDidUpdate
      // because in most cases, users would not be using these, so we
      // will fetch only when the user initially goes there, hence saving extra queries
      if (this.state.isCourseScoped) {
        this.props.fetchCourseScopedRevisions(this.props.course, this.props.courseScopedLimit);
      } else {
        this.props.fetchRevisions(this.props.course);
      }
    }
  },

  getLoadingMessage() {
    if (!this.state.isCourseScoped) {
      if (!this.props.assessmentsLoaded) {
        return 'Loading page assessments';
      }
      if (!this.props.referencesLoaded) {
        return 'Loading references';
      }
    } else {
      if (!this.props.courseSpecificAssessmentsLoaded) {
        return 'Loading page assessments';
      }
      if (!this.props.courseSpecificReferencesLoaded) {
        return 'Loading references';
      }
    }
  },

  toggleCourseSpecific() {
    const toggledIsCourseScoped = !this.state.isCourseScoped;
    this.setState({ isCourseScoped: toggledIsCourseScoped });

    // If user reaches the course scoped part initially, and there are no
    // loaded course scoped revisions, we fetch course scoped revisions
    if (toggledIsCourseScoped && !this.props.courseScopedRevisionsLoaded) {
      this.props.fetchCourseScopedRevisions(this.props.course, this.props.courseScopedLimit);
    }
  },

  revisionFilterButtonText() {
    if (this.state.isCourseScoped) {
      return I18n.t('revisions.show_all');
    }
    return I18n.t('revisions.show_course_specific');
  },

  sortSelect(e) {
    return this.props.sortRevisions(e.value);
  },

  // We disable show more button if there is a request which is still resolving
  // by keeping track of revisionsLoaded and courseScopedRevisionsLoaded
  showMore() {
    if (this.state.isCourseScoped) {
      return this.props.fetchCourseScopedRevisions(this.props.course, this.props.courseScopedLimit + 100);
    }
    return this.props.fetchRevisions(this.props.course);
  },

  render() {
    // Boolean to indicate whether the revisions in the current section (all scoped or course scoped are loaded)
    const loaded = (!this.state.isCourseScoped && this.props.revisionsLoaded) || (this.state.isCourseScoped && this.props.courseScopedRevisionsLoaded);
    const revisions = this.state.isCourseScoped ? this.props.revisionsDisplayedCourseSpecific : this.props.revisionsDisplayed;
    let metaDataLoading;

    if (!this.state.isCourseScoped) {
      metaDataLoading = !this.props.referencesLoaded || !this.props.assessmentsLoaded;
    } else {
      metaDataLoading = !this.props.courseSpecificReferencesLoaded || !this.props.courseSpecificAssessmentsLoaded;
    }
    let showMoreButton;
    if ((!this.state.isCourseScoped && !this.props.limitReached) || (this.state.isCourseScoped && !this.props.courseScopedLimitReached)) {
      showMoreButton = <div><button className="button ghost stacked right" onClick={this.showMore}>{I18n.t('revisions.see_more')}</button></div>;
    }

    // we only fetch articles data for a max of 500 articles(for course specific revisions).
    // If there are more than 500 articles, the toggle button is not shown
    const revisionFilterButton = <div><button className="button ghost stacked right" onClick={this.toggleCourseSpecific}>{this.revisionFilterButtonText()}</button></div>;
    const options = [
      { value: 'rating_num', label: I18n.t('revisions.class') },
      { value: 'title', label: I18n.t('revisions.title') },
      { value: 'revisor', label: I18n.t('revisions.edited_by') },
      { value: 'characters', label: I18n.t('revisions.chars_added') },
      { value: 'references_added', label: I18n.t('revisions.references') },
      { value: 'date', label: I18n.t('revisions.date_time') },
    ];
    return (
      <div id="revisions">
        <div className="section-header">
          <h3>{I18n.t('application.recent_activity')}</h3>
          {this.props.course.article_count <= ARTICLE_FETCH_LIMIT && revisionFilterButton}
          <div className="sort-container">
            <Select
              name="sorts"
              onChange={this.sortSelect}
              options={options}
              styles={sortSelectStyles}
            />
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
        {loaded && metaDataLoading && <ProgressIndicator message={this.getLoadingMessage()}/>}
      </div>
    );
  }
});

const mapStateToProps = state => ({
  courseScopedLimitReached: state.revisions.courseScopedLimitReached,
  limitReached: state.revisions.limitReached,
  revisionsDisplayed: state.revisions.revisionsDisplayed,
  revisionsDisplayedCourseSpecific: state.revisions.revisionsDisplayedCourseSpecific,
  courseSpecificAssessmentsLoaded: state.revisions.courseSpecificAssessmentsLoaded,
  wikidataLabels: state.wikidataLabels.labels,
  courseScopedRevisionsLoaded: state.revisions.courseScopedRevisionsLoaded,
  revisionsLoaded: state.revisions.revisionsLoaded,
  sort: state.revisions.sort,
  referencesLoaded: state.revisions.referencesLoaded,
  assessmentsLoaded: state.revisions.assessmentsLoaded,
  courseSpecificReferencesLoaded: state.revisions.courseSpecificReferencesLoaded
});

const mapDispatchToProps = {
  fetchRevisions,
  sortRevisions,
  fetchCourseScopedRevisions
};

export default connect(mapStateToProps, mapDispatchToProps)(RevisionHandler);
