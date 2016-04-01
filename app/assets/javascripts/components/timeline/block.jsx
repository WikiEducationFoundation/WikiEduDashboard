import React from 'react';
import TextInput from '../common/text_input.cjsx';
import TextAreaInput from '../common/text_area_input.cjsx';
import TrainingModules from '../training_modules.cjsx';
import Checkbox from '../common/checkbox.cjsx';
import Select from '../common/select.cjsx';
import BlockActions from '../../actions/block_actions.coffee';
import GradeableActions from '../../actions/gradeable_actions.coffee';

const Block = React.createClass({
  displayName: 'Block',
  propTypes: {
    block: React.PropTypes.object,
    editableBlockIds: React.PropTypes.array,
    gradeable: React.PropTypes.object,
    saveBlockChanges: React.PropTypes.func,
    cancelBlockEditable: React.PropTypes.func,
    toggleFocused: React.PropTypes.func,
    isDragging: React.PropTypes.bool,
    allTrainingModules: React.PropTypes.array,
    editPermissions: React.PropTypes.bool,
    weekStart: React.PropTypes.date
  },
  updateBlock(valueKey, value) {
    const toPass = $.extend(true, {}, this.props.block);
    toPass[valueKey] = value;
    delete toPass.deleteBlock;
    return BlockActions.updateBlock(toPass);
  },
  passedUpdateBlock(_, modules) {
    const newBlock = $.extend(true, {}, this.props.block);
    const selectedIds = modules.map(module => module.value);
    newBlock.training_module_ids = selectedIds;
    return BlockActions.updateBlock(newBlock);
  },
  deleteBlock() {
    if (confirm('Are you sure you want to delete this block? This will delete the block and all of its content.\nThis cannot be undone.')) {
      return BlockActions.deleteBlock(this.props.block.id);
    }
  },
  _setEditable() {
    return BlockActions.setEditable(this.props.block.id);
  },
  _isEditable() {
    if (this.props.editableBlockIds) {
      return this.props.editableBlockIds.indexOf(this.props.block.id) >= 0;
    }
  },
  updateGradeable(valueKey, value) {
    if (value === 'true') {
      return GradeableActions.addGradeable(this.props.block);
    }
    return GradeableActions.deleteGradeable(this.props.gradeable.id);
  },
  render() {
    const isGraded = this.props.gradeable !== undefined && !this.props.gradeable.deleted;
    let className = 'block';
    className += ` block-kind-${this.props.block.kind}`;

    let blockActions = '';
    if (this._isEditable()) {
      blockActions = (
        <div className="float-container block__block-actions">
          <button onClick={this.props.saveBlockChanges.bind(null, this.props.block.id)} className="button dark pull-right no-clear">Save</button>
          <span role="button" onClick={this.props.cancelBlockEditable.bind(null, this.props.block.id)} className="span-link pull-right no-clear">Cancel</span>
        </div>
      );
    }

    let dueDateRead = '';
    if (this.props.block.due_date) {
      dueDateRead = (
        <TextInput
          onChange={this.updateBlock}
          value={this.props.block.due_date}
          value_key={'due_date'}
          editable={false}
          label={'Due'}
          show={this.props.block.due_date !== undefined}
          onFocus={this.props.toggleFocused}
          onBlur={this.props.toggleFocused}
          p_tag_classname={'block__read__due-date'}
        />
      );
    }

    let deleteBlockButton = '';
    let graded = '';
    if (this._isEditable()) {
      if (!this.props.block.is_new) {
        deleteBlockButton = (
          <div className="delete-block-container"><button className="danger" onClick={this.deleteBlock}>Delete Block</button></div>
        );
      }
      className = ' editable';
      if (this.props.isDragging) {
        className += ' dragging';
      }
      graded = (
        <Checkbox
          value={isGraded}
          onChange={this.updateGradeable}
          value_key={"gradeable"}
          editable={this._isEditable()}
          label={"Graded"}
          container_class={"graded"}
        />
      );
    }

    let modules = '';
    if (this.props.block.training_modules || this._isEditable()) {
      modules = (
        <TrainingModules
          onChange={this.passedUpdateBlock}
          all_modules={this.props.allTrainingModules}
          block_modules={this.props.block.training_modules}
          editable={this._isEditable()}
          block={this.props.block}
        />
      );
    }

    const content = (
      <div className="block__editor-container">
        <TextAreaInput
          onChange={this.updateBlock}
          value={this.props.block.content || 'Block description…'}
          value_key="content"
          editable={this._isEditable()}
          rows="4"
          onFocus={this.props.toggleFocused}
          onBlur={this.props.toggleFocused}
          wysiwyg
          className="block__block-content"
        />
        {modules}
      </div>
    );

    let dueDateSpacer = '';
    if (this.props.block.due_date) {
      dueDateSpacer = (<span className="block__due-date-spacer"> - </span>);
    }

    let editButton = '';
    if (this.props.editPermissions) {
      editButton = (
        <div className="block__edit-button-container">
          <button className="pull-right button ghost-button block__edit-block" onClick={this._setEditable}>Edit</button>
        </div>
      );
    }

    return (
      <li className={className}>
        {blockActions}
        {editButton}
        <div className="block__edit-container">
          <h4 className={ `block-title ${this._isEditable() ? ' block-title--editing' : ''}` }>
            <TextInput
              onChange={this.updateBlock}
              value={this.props.block.title}
              value_key={'title'}
              editable={this._isEditable()}
              placeholder="Block title"
              show={this.props.block.title && !this._isEditable()}
              className="title pull-left"
              spacer=""
              onFocus={this.props.toggleFocused}
              onBlur={this.props.toggleFocused}
            />
            <TextInput
              onChange={this.updateBlock}
              value={this.props.block.title}
              value_key="title"
              editable={this._isEditable()}
              placeholder="Block title"
              label="Title"
              className="pull-left"
              spacer=""
              show={this._isEditable()}
              onFocus={this.props.toggleFocused}
              onBlur={this.props.toggleFocused}
            />
          </h4>
          <div className="block__block-type">
            <Select
              onChange={this.updateBlock}
              value={this.props.block.kind}
              value_key={'kind'}
              editable={this._isEditable()}
              options={['In Class', 'Assignment', 'Milestone', 'Custom']}
              show={this.props.block.kind < 3 || this._isEditable()}
              label="Block type"
              spacer=""
              popover_text={I18n.t('timeline.block_type')}
            />
            {dueDateSpacer}
            {dueDateRead || (isGraded ? (<span className="block__default-due-date">{I18n.t('timeline.due_default')}</span>) : '')}
          </div>
        </div>
        <div className="block__edit-container">
          <div className="block__block-due-date">
            <TextInput
              onChange={this.updateBlock}
              value={this.props.block.due_date}
              value_key="due_date"
              editable={this._isEditable()}
              type="date"
              label="Due date"
              spacer=""
              placeholder="Due date"
              isClearable
              show={this._isEditable() && parseInt(this.props.block.kind) === 1}
              date_props={ { minDate: this.props.weekStart } }
              onFocus={this.props.toggleFocused}
              onBlur={this.props.toggleFocused}
            />
          </div>
          {graded}
        </div>
        {content}
        {deleteBlockButton}
      </li>
    );
  }
});

export default Block;
