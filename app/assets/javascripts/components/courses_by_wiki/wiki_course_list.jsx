import React from 'react';
import { useDispatch } from 'react-redux';
import { sortWikiCourses, } from '../../actions/course_actions';
import CourseList from '../course/course_list';
import ActiveCourseRow from '../course/active_course_row';

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
  average_word_count: {
    label: I18n.t('metrics.word_count_average'),
    hidden: true
  },
  trained_count: {
    label: I18n.t('courses.untrained'),
    hidden: true
  },
  ...(!Features.wikiEd ? {
    creation_date: {
      label: I18n.t('courses.creation_date'),
      desktop_only: false
    }
  } : {}),
};

// this component shows the courses of a particular Wiki
const CourseWikiList = ({ courses, sort }) => {
  const dispatch = useDispatch();
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
    dispatch(sortWikiCourses(key));
  };

  return (
    <CourseList
      keys={keys}
      courses={courses}
      none_message="No active courses"
      sortBy={sortBy}
      RowElement={ActiveCourseRow}
      headerText={I18n.t(`${course_string_prefix}.courses`)}
      showSortDropdown
    />
  );
};

export default CourseWikiList;
