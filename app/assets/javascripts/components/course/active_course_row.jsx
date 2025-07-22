import React from 'react';

const ActiveCourseRow = ({ course }) => {
  return (
    <tr>
      <td className="table-link-cell title">
        <a href={`/courses/${course.slug}/`}>{course.title}</a>
      </td>
      <td className="table-link-cell revisions">
        <a href={`/courses/${course.slug}/`}>{course.recent_revision_count}</a>
      </td>
      <td className="table-link-cell word-count">
        <a href={`/courses/${course.slug}/`}>
          <div>
            {course.human_word_count}
          </div>
          <small>
            ({I18n.t('metrics.per_user', { number: course.average_word_count })})
          </small>
        </a>
      </td>
      <td className="table-link-cell references">
        <a href={`/courses/${course.slug}/`}>{course.human_references_count}</a>
      </td>
      <td className="table-link-cell view-sum">
        <a href={`/courses/${course.slug}/`}>{course.human_view_sum}</a>
      </td>
      <td className="table-link-cell user-count">
        <a href={`/courses/${course.slug}/`}>
          <div>
            {course.user_count}
          </div>
          <small>
            {I18n.t('users.training_complete_count', { count: course.trained_count })}
          </small>
        </a>
      </td>
      {
      !Features.wikiEd && (
        <td className="table-link-cell creation-date">
          <a href={`/courses/${course.slug}/`}>{course.creation_date}</a>
        </td>
        )
      }
    </tr>
  );
};

export default ActiveCourseRow;
