import React from 'react';
import { connect } from 'react-redux';
import { map } from 'lodash-es';

import CourseUtils from '../../utils/course_utils.js';

const TagList = ({ tags, course }) => {
  const lastIndex = tags.length - 1;
  const renderedTags = (tags.length > 0
    ? map(tags, (tag, index) => {
      const comma = (index !== lastIndex) ? ', ' : '';
      return <span key={`${tag.tag}${tag.id}`}>{tag.tag}{comma}</span>;
    })
    : <span>{I18n.t('courses.none')}</span>);

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
