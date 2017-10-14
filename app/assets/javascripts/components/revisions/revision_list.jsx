import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Editable from '../high_order/editable.jsx';

import List from '../common/list.jsx';
import Revision from './revision.jsx';
import RevisionStore from '../../stores/revision_store.js';
import ServerActions from '../../actions/server_actions.js';
import CourseUtils from '../../utils/course_utils.js';

const getState = () => ({ revisions: RevisionStore.getModels() });

const RevisionList = createReactClass({
  displayName: 'RevisionList',

  propTypes: {
    revisions: PropTypes.array,
    course: PropTypes.object
  },

  render() {
    const elements = this.props.revisions.map(revision => {
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
      edited_by: {
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
        none_message={CourseUtils.i18n('revisions_none', this.props.course.string_prefix)}
        store={RevisionStore}
      />
    );
  }
}
);

export default Editable(RevisionList, [RevisionStore], ServerActions.saveRevisions, getState);
