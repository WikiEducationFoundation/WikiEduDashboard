import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { fetchActiveCampaignCourses, fetchActiveCourses, sortActiveCourses } from '../../actions/course_actions';
import Loading from '../common/loading';
import ActiveCourseRow from './active_course_row';
import CourseList from './course_list';

const course_string_prefix = Features.course_string_prefix;
const keys = {
  title: {
    label: I18n.t(`${course_string_prefix}.courses`),
  },
  recent_revision_count: {
    label: I18n.t('metrics.revisions'),
    info_key: 'courses.revisions_doc',
    info_key_options: { timeframe: 7 }
  },
  word_count: {
    label: I18n.t('metrics.word_count'),
    desktop_only: false,
    info_key: `${course_string_prefix}.word_count_doc`
  },
  references_count: {
    label: I18n.t('metrics.references_count'),
    desktop_only: false,
    info_key: 'metrics.references_doc'
  },
  view_sum: {
    label: I18n.t('metrics.view'),
    desktop_only: false,
    info_key: 'courses.view_doc'
  },
  user_count: {
    label: I18n.t('users.editors'),
    desktop_only: false,
  },
  ...(!Features.wikiEd ? {
    creation_date: {
      label: I18n.t('courses.creation_date'),
      desktop_only: false
    }
  } : {}),
};

// if `defaultCampaignOnly` is set to true, it will show the active courses from the default campaign only
// if it is false, it will show the active courses from all campaigns
const ActiveCourseList = ({ defaultCampaignOnly = true }) => {
  const { isLoaded, courses, sort } = useSelector(state => state.active_courses);
  const dispatch = useDispatch();

  useEffect(() => {
    if (defaultCampaignOnly) {
      dispatch(fetchActiveCampaignCourses(Features.default_campaign_slug));
    } else {
      dispatch(fetchActiveCourses());
    }
  }, []);

  if (sort.key) {
    // eslint-disable-next-line no-restricted-syntax
    for (const key of Object.keys(keys)) {
      if (key === sort.key) {
        keys[sort.key].order = (sort.sortKey) ? 'asc' : 'desc';
      } else {
        keys[key].order = undefined;
      }
    }
  }

  const sortBy = (key) => {
    dispatch(sortActiveCourses(key));
  };
  if (!isLoaded) {
    return <Loading />;
  }
  return (
    <CourseList keys={keys} courses={courses} none_message="No active courses" sortBy={sortBy} RowElement={ActiveCourseRow} headerText={I18n.t('courses.active_courses')} showSortDropdown/>
  );
};

export default ActiveCourseList;
