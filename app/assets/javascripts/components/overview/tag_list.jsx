import React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';

import CourseUtils from '../../utils/course_utils.js';

const TagList = ({ tags, course }) => {
  const lastIndex = tags.length - 1;
  const renderedTags = (tags.length > 0
    ? _.map(tags, (tag, index) => {
      const comma = (index !== lastIndex) ? ', ' : '';
      return <span key={`${tag.tag}${tag.id}`}>{tag.tag}{comma}</span>;
    })
    : I18n.t('courses.none'));

  return (
    <span key="tags_list" className="tags">
      <strong>{CourseUtils.i18n('tags', course.string_prefix)}</strong>
      <span> {renderedTags}</span>
    </span>
  );
};

const mapStateToProps = state => ({
  tags: state.tags.tags
});

export default connect(mapStateToProps)(TagList);
