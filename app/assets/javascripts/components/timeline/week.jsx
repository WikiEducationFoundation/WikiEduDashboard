import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { useSpring, Spring } from 'react-spring';
import TransitionGroup from '../common/css_transition_group';
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
    meetings: PropTypes.array,
    blocks: PropTypes.array,
    edit_permissions: PropTypes.bool,
    editableBlockIds: PropTypes.array,
    reorderable: PropTypes.bool,
    editableTitles: PropTypes.bool,
    onBlockDrag: PropTypes.func,
    onMoveBlockUp: PropTypes.func,
    onMoveBlockDown: PropTypes.func,
    usingCustomTitles: PropTypes.bool,
    updateTitle: PropTypes.func,
    canBlockMoveUp: PropTypes.func,
    canBlockMoveDown: PropTypes.func,
    saveBlockChanges: PropTypes.func,
    cancelBlockEditable: PropTypes.func,
    addBlock: PropTypes.func,
    deleteWeek: PropTypes.func,
    all_training_modules: PropTypes.array,
    weeksBeforeTimeline: PropTypes.number,
    trainingLibrarySlug: PropTypes.string.isRequired,
    current_user: PropTypes.object
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
    let weekDatesContent;
    let meetDates;
    if (this.props.meetings && this.props.meetings.length > 0) {
      meetDates = `Meetings: ${this.props.meetings.join(', ')}`;
    }
    if (this.props.meetings) {
      weekDatesContent = `${dateCalc.start()} - ${dateCalc.end()}`;
    } else {
      weekDatesContent = `Week of ${dateCalc.start()} — AFTER TIMELINE END DATE!`;
    }
    const meetDatesDiv = (
      <div className="margin-bottom">
        {meetDates}
      </div>
    );
    let weekTitleContent;
    if (this.props.week.title) {
      weekTitleContent = this.props.week.title;
    } else {
      weekTitleContent = I18n.t('timeline.week_number', { number: this.weekNumber() });
    }
    const weekId = this.props.week.id;
    const weekTitle = this.props.editableTitles ? (
      <input
        className="week-index week-title-input"
        defaultValue={weekTitleContent}
        maxLength={20}
        onChange={event => this.props.updateTitle(weekId, event.target.value)}
      />
    ) : (
      <p className="week-index">{weekTitleContent}<span className="week-range"> ({weekDatesContent})</span></p>
    );
    const blocks = this.props.blocks.map((block, i) => {
      // If in reorderable mode
      if (this.props.reorderable) {
        const orderableBlock = (value) => {
          const rounded = Math.round(value.y);
          const animating = rounded !== i * 75;
          const willChange = animating ? 'top' : 'initial';
          const blockLineStyle = useSpring({
            top: 0,
            position: 'absolute',
            width: '100%',
            left: 0,
            willChange,
            marginLeft: 0,
            marginBottom: '2em'
          });
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
          <Spring key={block.id} from={{ y: i * 75 }} to={{ y: i * 75 }}>
            {orderableBlock}
          </Spring>
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
          current_user={this.props.current_user}
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
          <TransitionGroup
            classNames="shrink"
            timeout={250}
          >
            <ul style={style} className="week__block-list list-unstyled">
              {blocks}
            </ul>
          </TransitionGroup>
        )
        : (
          <ul className="week__block-list list-unstyled">
            {blocks}
          </ul>
        )
    );

    let weekClassName = `Week Week-${this.props.index}`;
    if (!this.props.meetings) {
      weekClassName += ' timeline-warning';
    }

    return (
      <li className={weekClassName}>
        <div className="week__week-header">
          {weekAddDelete}
          {weekTitle}
          {meetDatesDiv}
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
