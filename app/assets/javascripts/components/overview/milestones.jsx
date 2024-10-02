import React from 'react';
import PropTypes from 'prop-types';
import { filter } from 'lodash-es';
import CourseDateUtils from '../../utils/course_date_utils';

const md = require('../../utils/markdown_it.js').default();

const Milestones = ({ timelineStart, allWeeks, course }) => {
  const milestoneBlockType = 2;

  const weekIsCompleted = (week, currentWeek) => {
    return week.weekNumber < currentWeek;
  };

  const currentWeek = CourseDateUtils.currentWeekOrder(timelineStart);
  const weekNumberOffset = CourseDateUtils.weeksBeforeTimeline(course);
  const blocks = [];

  allWeeks.forEach((week) => {
    if (week.empty) return;

    const milestoneBlocks = filter(
      week.blocks,
      block => block.kind === milestoneBlockType
    );
    milestoneBlocks.forEach((block) => {
      let classNames = 'module__data';
      if (weekIsCompleted(week, currentWeek)) {
        classNames += ' completed';
      }
      const rawHtml = md.render(block.content || '');
      const completionNote = weekIsCompleted(week, currentWeek)
        ? '- Complete'
        : undefined;
      blocks.push(
        <div key={block.id} className="section-header">
          <div className={classNames}>
            <p>
              {I18n.t('week')} {week.weekNumber + weekNumberOffset}{' '}
              {completionNote}
            </p>
            <div
              className="markdown"
              dangerouslySetInnerHTML={{ __html: rawHtml }}
            />
            <hr />
          </div>
        </div>
      );
    });
  });

  if (!blocks.length) {
    return null;
  }

  return (
    <div className="module milestones">
      <div className="section-header">
        <h3>{I18n.t('blocks.milestones.title')}</h3>
      </div>
      {blocks}
    </div>
  );
};

Milestones.propTypes = {
  timelineStart: PropTypes.string.isRequired,
  allWeeks: PropTypes.array.isRequired,
  course: PropTypes.object.isRequired,
};

export default Milestones;
