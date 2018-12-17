import React from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import CourseUtils from '../../utils/course_utils.js';

const AvailableArticlesList = ({ elements }) => {
  const keys = {
    rating_num: {
      label: I18n.t('articles.rating'),
      desktop_only: true
    },
    title: {
      label: I18n.t('articles.title'),
      desktop_only: false
    }
  };

  return (
    <List
      elements={elements}
      keys={keys}
      table_key="articles"
      none_message={CourseUtils.i18n('no_available', 'assignments')}
      sortable={false}
    />
  );
};

AvailableArticlesList.propTypes = {
  elements: PropTypes.array
};

export default AvailableArticlesList;
