import React from 'react';
import Editable from '../high_order/editable.jsx';
import List from '../common/list.jsx';
import AssignmentStore from '../../stores/assignment_store.coffee';
import ArticleStore from '../../stores/article_store.coffee';
import ServerActions from '../../actions/server_actions.js';
import CourseUtils from '../../utils/course_utils.js';

const getState = () => ({ assignments: AssignmentStore.getModels() });

const AvailableArticlesList = React.createClass({
  displayName: 'AvailableArticlesList',
  propTypes: {
    elements: React.PropTypes.array
  },
  render() {
    let keys = {
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
        elements={this.props.elements}
        keys={keys}
        table_key="articles"
        none_message={CourseUtils.i18n('no_available', 'assignments')}
        store={AssignmentStore}
        sortable={false}
      />
    );
  }
}
);

export default Editable(AvailableArticlesList, [ArticleStore, AssignmentStore], ServerActions.saveStudents, getState);
