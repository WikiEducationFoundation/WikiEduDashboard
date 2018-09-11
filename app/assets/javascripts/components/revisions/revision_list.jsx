import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import List from '../common/list.jsx';
import Revision from './revision.jsx';
import DiffViewer from './diff_viewer.jsx';
import CourseUtils from '../../utils/course_utils.js';

const RevisionList = createReactClass({
  displayName: 'RevisionList',

  propTypes: {
    revisions: PropTypes.array,
    course: PropTypes.object
  },

  getInitialState() {
    return {
      showDiffView: false,
      revision: {}
    };
  },

  handleShowDiff(revision, index) {
    return () => {
      this.setState({ showDiffView: true, revision: revision, index });
    };
  },

  hideDiff() {
    this.setState({ showDiffView: false });
  },

  handleNext() {
    if (this.state.index === this.props.revisions.length) {
      return;
    }
    const revision = this.props.revisions[this.state.index + 1];
    this.setState({ revision, index: this.state.index + 1 });
  },

  handlePrevious() {
    if (this.state.index === 0) {
      return;
    }
    const revision = this.props.revisions[this.state.index + -1];
    this.setState({ revision, index: this.state.index + -1 });
  },

  render() {
    const { revisions, course, sortBy, wikidataLabels, sort } = this.props;

    const elements = revisions.map((revision, index) => {
      return (
        <Revision
          revision={revision}
          key={revision.id}
          wikidataLabel={wikidataLabels[revision.title]}
          course={course}
          handleShowDiff={this.handleShowDiff(revision, index)}
        />
      );
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
    if (sort.key) {
      const order = sort.sortKey ? 'asc' : 'desc';
      keys[sort.key].order = order;
    }
    return (
      <div>
        <List
          elements={elements}
          keys={keys}
          table_key="revisions"
          none_message={CourseUtils.i18n(
            'revisions_none',
            course.string_prefix
          )}
          sortBy={sortBy}
          sortable={true}
        />
        <DiffViewer
          revision={this.state.revision}
          editors={[this.state.revision.revisor]}
          showDiffView={this.state.showDiffView}
          hideDiff={this.hideDiff}
          handleNext={this.handleNext}
          handlePrevious={this.handlePrevious}
        />
      </div>
    );
  }
});

export default RevisionList;
