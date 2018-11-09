import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { Motion, spring } from 'react-motion';
import ReactCSSTG from 'react-transition-group/CSSTransitionGroup';
import Block from './block.jsx';
import OrderableBlock from './orderable_block.jsx';

import DateCalculator from '../../utils/date_calculator.js';

const Week = createReactClass({
  displayName: 'Week',
  propTypes: {
    week: PropTypes.object,
    index: PropTypes.number,
    timeline_start: PropTypes.string,
    timeline_end: PropTypes.string,
    meetings: PropTypes.string,
    blocks: PropTypes.array,
    edit_permissions: PropTypes.bool,
    editableBlockIds: PropTypes.array,
    reorderable: PropTypes.bool,
    onBlockDrag: PropTypes.func,
    onMoveBlockUp: PropTypes.func,
    onMoveBlockDown: PropTypes.func,
    canBlockMoveUp: PropTypes.func,
    canBlockMoveDown: PropTypes.func,
    saveBlockChanges: PropTypes.func,
    cancelBlockEditable: PropTypes.func,
    addBlock: PropTypes.func,
    deleteWeek: PropTypes.func,
    all_training_modules: PropTypes.array,
    weeksBeforeTimeline: PropTypes.number,
    trainingLibrarySlug: PropTypes.string.isRequired
  },
  getInitialState() {
    return { focusedBlockId: null };
  },
  componentDidMount() {
    const hash = location.hash.substring(1);
    const weekNo = this.weekNumber();
    if (hash === `week-${weekNo}`) {
      const week = document.getElementsByName(hash)[0];
      week.scrollIntoView();
    }
  },
  addBlock() {
    this._scrollToAddedBlock();
    return this.props.addBlock(this.props.week.id);
  },
  toggleFocused(blockId) {
    if (this.state.focusedBlockId === blockId) {
      return this.setState({ focusedBlockId: null });
    }
    return this.setState({ focusedBlockId: blockId });
  },
  _scrollToAddedBlock() {
    const wk = document.getElementsByClassName(`week-${this.props.index}`)[0];
    const scrollTop = window.scrollY || document.body.scrollTop;
    const bottom = Math.abs(__guard__(wk, x => x.getBoundingClientRect().bottom));
    const elBottom = (bottom + scrollTop) - 50;
    return window.scrollTo({ top: elBottom, behavior: 'smooth' });
  },
  weekNumber() {
    return this.props.index + this.props.weeksBeforeTimeline;
  },
  render() {
    let style;
    const dateCalc = new DateCalculator(this.props.timeline_start, this.props.timeline_end, this.props.index, { zeroIndexed: false });

    let weekDates;
    if (this.props.meetings) {
      weekDates = (
        <span className="week__week-dates pull-right">
          {dateCalc.start()} - {dateCalc.end()} {this.props.meetings}
        </span>
      );
    } else {
      weekDates = (
        <span className="week__week-dates pull-right">
          Week of {dateCalc.start()} — AFTER TIMELINE END DATE!
        </span>
      );
    }


    const blocks = this.props.blocks.map((block, i) => {
      // If in reorderable mode
      if (this.props.reorderable) {
        const orderableBlock = (value) => {
          const rounded = Math.round(value.y);
          const animating = rounded !== i * 75;
          const willChange = animating ? 'top' : 'initial';
          const blockLineStyle = {
            top: rounded,
            position: 'absolute',
            width: '100%',
            left: 0,
            willChange,
            marginLeft: 0
          };
          return (
            <li style={blockLineStyle}>
              <OrderableBlock
                block={block}
                canDrag={true}
                animating={animating}
                onDrag={this.props.onBlockDrag.bind(null, i)}
                onMoveUp={this.props.onMoveBlockUp.bind(null, block.id)}
                onMoveDown={this.props.onMoveBlockDown.bind(null, block.id)}
                disableDown={!this.props.canBlockMoveDown(block, i)}
                disableUp={!this.props.canBlockMoveUp(block, i)}
                index={i}
                title={block.title}
                kind={[I18n.t('timeline.block_in_class'), I18n.t('timeline.block_assignment'), I18n.t('timeline.block_milestone'), I18n.t('timeline.block_custom')][block.kind]}
              />
            </li>
          );
        };

        return (
          <Motion key={block.id} defaultStyle={{ y: i * 75 }} style={{ y: spring(i * 75, [220, 30]) }}>
            {orderableBlock}
          </Motion>
        );
      }
      // If not in reorderable mode
      return (
        <Block
          toggleFocused={this.toggleFocused.bind(this, block.id)}
          block={block}
          key={block.id}
          editPermissions={this.props.edit_permissions}
          deleteBlock={this.props.deleteBlock}
          week_index={this.props.index}
          weekStart={dateCalc.startDate()}
          all_training_modules={this.props.all_training_modules}
          editableBlockIds={this.props.editableBlockIds}
          saveBlockChanges={this.props.saveBlockChanges}
          setBlockEditable={this.props.setBlockEditable}
          cancelBlockEditable={this.props.cancelBlockEditable}
          updateBlock={this.props.updateBlock}
          trainingLibrarySlug={this.props.trainingLibrarySlug}
        />
      );
    });

    const addBlock = !this.props.reorderable ? (
      <button className="pull-right week__add-block" href="" onClick={this.addBlock}>Add Block</button>
    ) : undefined;

    const deleteWeek = !this.props.reorderable && !this.props.week.is_new ? (
      <button className="pull-right week__delete-week" href="" onClick={this.props.deleteWeek}>Delete Week</button>
    ) : undefined;

    const weekAddDelete = this.props.edit_permissions ? (
      <div className="week__week-add-delete pull-right">
        {addBlock}
        {deleteWeek}
      </div>
    ) : undefined;

    const weekContent = (
      this.props.reorderable
        ? (style = {
          position: 'relative',
          height: blocks.length * 75,
          transition: 'height 500ms ease-in-out'
        },
          <ReactCSSTG transitionName="shrink" transitionEnterTimeout={250} transitionLeaveTimeout={250} component="ul" className="week__block-list list-unstyled" style={style}>
            {blocks}
          </ReactCSSTG>
        )
        : (
          <ul className="week__block-list list-unstyled">
            {blocks}
          </ul>
        )
    );

    let weekClassName = `week week-${this.props.index}`;
    if (!this.props.meetings) {
      weekClassName += ' timeline-warning';
    }

    return (
      <li className={weekClassName}>
        <div className="week__week-header">
          {weekAddDelete}
          {weekDates}
          <p className="week-index">{I18n.t('timeline.week_number', { number: this.weekNumber() })}</p>
        </div>
        {weekContent}
      </li>
    );
  }
});

export default Week;

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
