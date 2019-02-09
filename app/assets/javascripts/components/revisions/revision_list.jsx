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

  shouldShowDiff(index) {
    return this.state.selectedIndex === index;
  },

  isFirstArticle(index) {
    return index === 0;
  },

  isLastArticle(index) {
    return index === this.props.revisions.length;
  },

  showPreviousArticle(index) {
    console.log('showPreviousArticle', index);
    this.setState({
      selectedIndex: index - 1
    });
  },

  showNextArticle(index) {
    console.log('showNextArticle', index);
    this.setState({
      selectedIndex: index + 1
    });
  },

  showDiff(index) {
    this.setState({
      selectedIndex: index
    });
  },

  hideDiff() {
    this.setState({
      selectedIndex: -1
    });
  },

  render() {
    const elements = this.props.revisions.map((revision, index) => {
      return <Revision
        revision={revision}
        key={revision.id}
        index={index}
        wikidataLabel={this.props.wikidataLabels[revision.title]}
        course={this.props.course}
        shouldShowDiff={this.shouldShowDiff}
        showDiff={this.showDiff}
        hideDiff={this.hideDiff}
        isFirstArticle={this.isFirstArticle}
        isLastArticle={this.isLastArticle}
        showPreviousArticle={this.showPreviousArticle}
        showNextArticle={this.showNextArticle}
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
    return (
      <List
        elements={elements}
        keys={keys}
        table_key="revisions"
        none_message={CourseUtils.i18n('revisions_none', this.props.course.string_prefix)}
        sortBy={this.props.sortBy}
        sortable={true}
      />
    );
  },
});

export default RevisionList;
