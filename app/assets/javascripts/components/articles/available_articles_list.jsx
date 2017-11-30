import React from 'react';
import PropTypes from 'prop-types';
import Editable from '../high_order/editable.jsx';
import List from '../common/list.jsx';
import AssignmentStore from '../../stores/assignment_store.js';
import ArticleStore from '../../stores/article_store.js';
import ServerActions from '../../actions/server_actions.js';
import CourseUtils from '../../utils/course_utils.js';

const getState = () => ({
  assignments: AssignmentStore.getModels()
});

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
      store={AssignmentStore}
      sortable={false}
    />
  );
};

AvailableArticlesList.propTypes = {
  elements: PropTypes.array
};

export default Editable(
  AvailableArticlesList,
  [ArticleStore, AssignmentStore],
  ServerActions.saveStudents,
  getState
);
