import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { useSelector, useDispatch } from 'react-redux';
import RevisionList from './revision_list.jsx';
import { fetchRevisions, sortRevisions, fetchCourseScopedRevisions } from '../../actions/revisions_actions.js';
import Loading from '../common/loading.jsx';
import ProgressIndicator from '../common/progress_indicator.jsx';
import { ARTICLE_FETCH_LIMIT } from '../../constants/revisions.js';
import Select from 'react-select';
import sortSelectStyles from '../../styles/sort_select';
import { getStudentUsers } from '../../selectors/index.js';

const RevisionHandler = ({ course, courseScopedLimit }) => {
  const [isCourseScoped, setIsCourseScoped] = useState(false);

  const dispatch = useDispatch();

  const revisionsDisplayed = useSelector(state => state.revisions.revisionsDisplayed);
  const revisionsDisplayedCourseSpecific = useSelector(state => state.revisions.revisionsDisplayedCourseSpecific);
  const courseScopedLimitReached = useSelector(state => state.revisions.courseScopedLimitReached);
  const limitReached = useSelector(state => state.revisions.limitReached);
  const courseSpecificAssessmentsLoaded = useSelector(state => state.revisions.courseSpecificAssessmentsLoaded);
  const wikidataLabels = useSelector(state => state.wikidataLabels.labels);
  const courseScopedRevisionsLoaded = useSelector(state => state.revisions.courseScopedRevisionsLoaded);
  const revisionsLoaded = useSelector(state => state.revisions.revisionsLoaded);
  const sort = useSelector(state => state.revisions.sort);
  const referencesLoaded = useSelector(state => state.revisions.referencesLoaded);
  const assessmentsLoaded = useSelector(state => state.revisions.assessmentsLoaded);
  const courseSpecificReferencesLoaded = useSelector(state => state.revisions.courseSpecificReferencesLoaded);
  const students = useSelector(state => getStudentUsers(state));

  useEffect(() => {
    // sets the title of this tab
    document.title = `${course.title} - ${I18n.t('application.recent_activity')}`;
    if (!revisionsLoaded) {
      // Fetching in advance initially only for all revisions
      // For Course Scoped Revisions, fetching in componentDidUpdate
      // because in most cases, users would not be using these, so we
      // will fetch only when the user initially goes there, hence saving extra queries
      if (isCourseScoped) {
        dispatch(fetchCourseScopedRevisions(course, courseScopedLimit));
      } else {
        dispatch(fetchRevisions(course));
      }
    }
  }, [course, isCourseScoped, revisionsLoaded]);

  const getLoadingMessage = () => {
    if (!isCourseScoped) {
      if (!assessmentsLoaded) {
        return 'Loading page assessments';
      }
      if (!referencesLoaded) {
        return 'Loading references';
      }
    } else {
      if (!courseSpecificAssessmentsLoaded) {
        return 'Loading page assessments';
      }
      if (!courseSpecificReferencesLoaded) {
        return 'Loading references';
      }
    }
  };

  const toggleCourseSpecific = () => {
    const toggledIsCourseScoped = !isCourseScoped;
    setIsCourseScoped(toggledIsCourseScoped);

    // If user reaches the course scoped part initially, and there are no
    // loaded course scoped revisions, we fetch course scoped revisions
    if (toggledIsCourseScoped && !courseScopedRevisionsLoaded) {
      dispatch(fetchCourseScopedRevisions(course, courseScopedLimit));
    }
  };

  const revisionFilterButtonText = () => {
    return isCourseScoped ? I18n.t('revisions.show_all') : I18n.t('revisions.show_course_specific');
  };

  const sortSelect = (e) => {
    dispatch(sortRevisions(e.value));
  };

  // We disable show more button if there is a request which is still resolving
  // by keeping track of revisionsLoaded and courseScopedRevisionsLoaded
  const showMore = () => {
    if (isCourseScoped) {
      dispatch(fetchCourseScopedRevisions(course, courseScopedLimit + 100));
    } else {
      dispatch(fetchRevisions(course));
    }
  };

  // Boolean to indicate whether the revisions in the current section (all scoped or course scoped are loaded)
  const loaded = (!isCourseScoped && revisionsLoaded) || (isCourseScoped && courseScopedRevisionsLoaded);
  const metaDataLoading = (!isCourseScoped ? (!referencesLoaded || !assessmentsLoaded) : (!courseSpecificReferencesLoaded || !courseSpecificAssessmentsLoaded));
  const showMoreButton = ((!isCourseScoped && !limitReached) || (isCourseScoped && !courseScopedLimitReached)) ? (
    <div><button type="button" className="button ghost stacked right" onClick={showMore}>{I18n.t('revisions.see_more')}</button></div>
  ) : null;

  // we only fetch articles data for a max of 500 articles(for course specific revisions).
  // If there are more than 500 articles, the toggle button is not shown
  const revisionFilterButton = (
    <div><button type="button" className="button ghost stacked right" onClick={toggleCourseSpecific}>{revisionFilterButtonText()}</button></div>
  );

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
        {course.article_count <= ARTICLE_FETCH_LIMIT && revisionFilterButton}
        <div className="sort-container">
          <Select
            name="sorts"
            onChange={sortSelect}
            options={options}
            styles={sortSelectStyles}
          />
        </div>
      </div>
      <div className="revision-list-container">
        <RevisionList
          revisions={isCourseScoped ? revisionsDisplayedCourseSpecific : revisionsDisplayed}
          loaded={loaded}
          course={course}
          sortBy={sortRevisions}
          wikidataLabels={wikidataLabels}
          sort={sort}
          students={students}
        />
      </div>
      {!loaded && <Loading />}
      {loaded && showMoreButton}
      {loaded && metaDataLoading && <ProgressIndicator message={getLoadingMessage()} />}
    </div>
  );
};

RevisionHandler.propTypes = {
  course: PropTypes.object,
  courseScopedLimit: PropTypes.number,
};

export default RevisionHandler;
