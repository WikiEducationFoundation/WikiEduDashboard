import React from 'react';
import PropTypes from 'prop-types';
import { filter } from 'lodash-es';
import CourseDateUtils from '../../utils/course_date_utils';

const md = require('../../utils/markdown_it.js').default();

const Milestones = ({ timelineStart, allWeeks, course }) => {
  const currentWeek = CourseDateUtils.currentWeekOrder(timelineStart);
  const weekNumberOffset = CourseDateUtils.weeksBeforeTimeline(course);

  const weekIsCompleted = (week) => {
    return week.weekNumber < currentWeek;
  };

  const blocks = allWeeks.flatMap((week) => {
    if (week.empty) return [];
    const milestoneBlocks = filter(week.blocks, block => block.kind === 2);
    return milestoneBlocks.map((block) => {
      let classNames = 'module__data';
      if (weekIsCompleted(week)) { classNames += ' completed'; }
      const rawHtml = md.render(block.content || '');
      const completionNote = weekIsCompleted(week) ? '- Complete' : undefined;
      return (
        <div key={block.id} className="section-header">
          <div className={classNames}>
            <p>Week {week.weekNumber + weekNumberOffset} {completionNote}</p>
            <div className="markdown" dangerouslySetInnerHTML={{ __html: rawHtml }} />
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
  course: PropTypes.object.isRequired
};

export default Milestones;
