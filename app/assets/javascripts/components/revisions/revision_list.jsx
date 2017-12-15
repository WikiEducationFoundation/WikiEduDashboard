import React from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import Revision from './revision.jsx';
import CourseUtils from '../../utils/course_utils.js';

const RevisionList = ({ revisions, course, sortBy }) => {
  const elements = revisions.map(revision => {
    return <Revision revision={revision} key={revision.id} />;
  });

  const keys = {
    rating_num: {
      label: I18n.t('revisions.class'),
      desktop_only: true
    },
    title: {
      label: I18n.t('revisions.title'),
      desktop_only: false
    },
    revisor: {
      label: I18n.t('revisions.edited_by'),
      desktop_only: true
    },
    characters: {
      label: I18n.t('revisions.chars_added'),
      desktop_only: true
    },
    date: {
      label: I18n.t('revisions.date_time'),
      desktop_only: true,
      info_key: 'revisions.time_doc'
    }
  };

  return (
    <List
      elements={elements}
      keys={keys}
      table_key="revisions"
      none_message={CourseUtils.i18n('revisions_none', course.string_prefix)}
      sortBy={sortBy}
    />
  );
};

RevisionList.propTypes = {
  revisions: PropTypes.array,
  course: PropTypes.object
};

export default RevisionList;
