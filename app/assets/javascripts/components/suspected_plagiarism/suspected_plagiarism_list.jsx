import React from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import createReactClass from 'create-react-class';
import SuspectedPlagiarism from './suspected_plagiarism';

const SuspectedPlagiarismList = createReactClass({
  displayName: 'SuspectedPlagiarismList',

  propTypes: {
    revisions: PropTypes.array,
    course: PropTypes.object,
    sortBy: PropTypes.func,
    sort: PropTypes.object
  },

  render() {
    const elements = this.props.revisions.map(revision =>
      <SuspectedPlagiarism revision={revision} key={revision.key}/>
    );

    const keys = {
      title: {
        label: I18n.t('revisions.title'),
        desktop_only: false
      },
      revisor: {
        label: I18n.t('revisions.edited_by'),
        desktop_only: true
      },
      date: {
        label: I18n.t('revisions.date_time'),
        desktop_only: true,
        info_key: 'revisions.time_doc'
      },
      report: {
        label: I18n.t('recent_activity.plagiarism_report'),
        desktop_only: true
      }
    };
    if (this.props.sort.key) {
      keys[this.props.sort.key].order = (this.props.sort.sortKey) ? 'asc' : 'desc';
    }

    // Until the revisions are loaded, we do not pass the none_message prop
    // This is done to avoid showing the none_message when the revisions are loading
    // initially because at that time the revisions is an empty array
    // Whether or not the revisions is really an empty array is confirmed after the revisions
    // are successfully loaded
    return (
      <List
        elements={elements}
        keys={keys}
        table_key="possible_plagiarism"
        none_message={this.props.loaded ? I18n.t('recent_activity.no_plagiarism') : ''}
        sortBy={this.props.sortBy}
        sortable={true}
      />
    );
  },
});

export default SuspectedPlagiarismList;
