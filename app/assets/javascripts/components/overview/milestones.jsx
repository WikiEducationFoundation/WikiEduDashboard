import React from 'react';
import createReactClass from 'create-react-class';
import _ from 'lodash';

import BlockStore from '../../stores/block_store.js';
import WeekStore from '../../stores/week_store.js';
import CourseStore from '../../stores/course_store.js';
const md = require('../../utils/markdown_it.js').default();

const getState = () =>
  ({
    weeks: WeekStore.getWeeks(),
    currentWeek: CourseStore.getCurrentWeek()
  })
;

const Milestones = createReactClass({
  displayName: I18n.t('blocks.milestones.title'),

  mixins: [BlockStore.mixin, WeekStore.mixin, CourseStore.mixin],

  getInitialState() {
    return getState();
  },

  storeDidChange() {
    return this.setState(getState());
  },

  milestoneBlockType: 2,

  weekIsCompleted(week) {
    return week.order < this.state.currentWeek;
  },

  render() {
    const blocks = [];
    this.state.weeks.map(week => {
      const milestoneBlocks = _.filter(week.blocks, block => block.kind === this.milestoneBlockType);
      return milestoneBlocks.map(block => {
        let classNames = 'module__data';
        if (this.weekIsCompleted(week)) { classNames += ' completed'; }
        const rawHtml = md.render(block.content);
        const completionNote = this.weekIsCompleted(week) ? '- Complete' : undefined;
        return blocks.push(
          <div key={block.id} className="section-header">
            <div className={classNames}>
              <p>Week {week.order} {completionNote}</p>
              <div className="markdown" dangerouslySetInnerHTML={{ __html: rawHtml }} />
              <hr />
            </div>
          </div>
        );
      }
      );
    }
    );

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
