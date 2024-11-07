import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import { filter } from 'lodash-es';

import CourseDateUtils from '../../utils/course_date_utils';
import DateCalculator from '../../utils/date_calculator';

const md = require('../../utils/markdown_it.js').default();

const Milestones = createReactClass({
  displayName: I18n.t('blocks.milestones.title'),

  propTypes: {
    timelineStart: PropTypes.string.isRequired,
    timelineEnd: PropTypes.string.isRequired,
    weeks: PropTypes.array.isRequired,
    allWeeks: PropTypes.array.isRequired,
    course: PropTypes.object.isRequired,
    weekDates: PropTypes.array.isRequired
  },

  milestoneBlockType: 2,

  weekIsCompleted(week, currentWeek) {
    return week.weekNumber < currentWeek;
  },

  render() {
    const currentWeek = CourseDateUtils.currentWeekOrder(this.props.timelineStart);
    const weekNumberOffset = CourseDateUtils.weeksBeforeTimeline(this.props.course);
    const blocks = [];

    
    this.props.allWeeks.map((week,navIndex) => {
      if (week.empty) return null;
      const milestoneBlocks = filter(week.blocks, block => block.kind === this.milestoneBlockType);
      return milestoneBlocks.map((block) => {
        if (
          !this.props.weekDates[navIndex]?.start || 
          !this.props.weekDates[navIndex]?.end || 
          this.props.weekDates[navIndex]?.start > this.props.weekDates[navIndex]?.end
        ) {
          return null;
        }        
        let classNames = 'module__data';
        if (this.weekIsCompleted(week, currentWeek)) { classNames += ' completed'; }
        const rawHtml = md.render(block.content || '');
        const completionNote = this.weekIsCompleted(week, currentWeek) ? '- Complete' : undefined;
        return blocks.push(
          <div key={block.id} className="section-header">
            <div className={classNames}>
              <p>Week {week.weekNumber + weekNumberOffset} ({this.props.weekDates[navIndex]?.start} - {this.props.weekDates[navIndex]?.end}) {completionNote}</p>
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
  }
});

export default Milestones;
