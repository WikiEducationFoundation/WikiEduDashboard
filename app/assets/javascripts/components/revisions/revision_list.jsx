import React from 'react';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import Revision from './revision.jsx';
import CourseUtils from '../../utils/course_utils.js';
import createReactClass from 'create-react-class';

const RevisionList = createReactClass({
  displayName: 'RevisionList',

  propTypes: {
    revisions: PropTypes.array,
    course: PropTypes.object,
    sortBy: PropTypes.func,
    wikidataLabels: PropTypes.object,
    sort: PropTypes.object
  },

  getInitialState() {
    return {
      selectedIndex: -1,
    };
  },

  showDiff(index) {
    this.setState({
      selectedIndex: index
    });
  },

  render() {
    const elements = this.props.revisions.map((revision, index) => {
      return <Revision
        revision={revision}
        key={revision.id}
        index={index}
        wikidataLabel={this.props.wikidataLabels[CourseUtils.removeNamespace(revision.title)]}
        course={this.props.course}
        setSelectedIndex={this.showDiff}
        lastIndex={this.props.revisions.length}
        selectedIndex={this.state.selectedIndex}
      />;
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
      references: {
        label: I18n.t('revisions.references'),
        desktop_only: true,
        info_key: 'metrics.references_doc'
      },
      date: {
        label: I18n.t('revisions.date_time'),
        desktop_only: true,
        info_key: 'revisions.time_doc'
      }
    };
    if (this.props.sort.key) {
      const order = (this.props.sort.sortKey) ? 'asc' : 'desc';
      keys[this.props.sort.key].order = order;
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
        table_key="revisions"
        none_message={this.props.loaded ? CourseUtils.i18n('revisions_none', this.props.course.string_prefix) : ''}
        sortBy={this.props.sortBy}
        sortable={true}
      />
    );
  },
});

export default RevisionList;
