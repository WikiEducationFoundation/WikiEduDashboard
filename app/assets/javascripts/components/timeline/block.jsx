import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TextInput from '../common/text_input.jsx';
import DatePicker from '../common/date_picker.jsx';
import TextAreaInput from '../common/text_area_input.jsx';
import TrainingModules from './training_modules.jsx';
import Checkbox from '../common/checkbox.jsx';
import BlockTypeSelect from './block_type_select.jsx';
import BlockActions from '../../actions/block_actions.js';
import GradeableActions from '../../actions/gradeable_actions.js';

const Block = createReactClass({
  displayName: 'Block',

  propTypes: {
    block: PropTypes.object,
    gradeable: PropTypes.object,
    editableBlockIds: PropTypes.array,
    editPermissions: PropTypes.bool,
    saveBlockChanges: PropTypes.func,
    cancelBlockEditable: PropTypes.func,
    toggleFocused: PropTypes.func,
    isDragging: PropTypes.bool,
    all_training_modules: PropTypes.array,
    weekStart: PropTypes.object
  },

  updateBlock(valueKey, value) {
    const toPass = $.extend(true, {}, this.props.block);
    toPass[valueKey] = value;
    delete toPass.deleteBlock;
    return BlockActions.updateBlock(toPass);
  },

  passedUpdateBlock(selectedIds) {
    const newBlock = $.extend(true, {}, this.props.block);
    newBlock.training_module_ids = selectedIds;
    return BlockActions.updateBlock(newBlock);
  },

  deleteBlock() {
    if (confirm('Are you sure you want to delete this block? This will delete the block and all of its content.\n\nThis cannot be undone.')) {
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
    return false;
  },

  updateGradeable(valueKey, value) {
    if (value === 'true') {
      return GradeableActions.addGradeable(this.props.block);
    }
    return GradeableActions.deleteGradeable(this.props.gradeable.id);
  },

  render() {
    const isEditable = this._isEditable();
    const isGraded = this.props.gradeable !== undefined && !this.props.gradeable.deleted;
    let className = 'block';
    className += ` block-kind-${this.props.block.kind}`;

    let blockTypeClassName = 'block__block-type';
    if (this.props.editPermissions) {
      blockTypeClassName += ' editable';
    }

    let blockActions;
    if (isEditable) {
      blockActions = (
        <div className="float-container block__block-actions">
          <button onClick={this.props.saveBlockChanges.bind(null, this.props.block.id)} className="button dark pull-right no-clear">Save</button>
          <span role="button" tabIndex={0} onClick={this.props.cancelBlockEditable.bind(null, this.props.block.id)} className="span-link pull-right no-clear">Cancel</span>
        </div>
      );
    }

    let dueDateRead;
    if (this.props.block.due_date !== null) {
      dueDateRead = (
        <TextInput
          onChange={this.updateBlock}
          value={this.props.block.due_date}
          value_key={'due_date'}
          editable={false}
          label="Due"
          show={Boolean(this.props.block.due_date)}
          onFocus={this.props.toggleFocused}
          onBlur={this.props.toggleFocused}
          p_tag_classname="block__read__due-date"
        />
      );
    }

    if (!dueDateRead) {
      dueDateRead = isGraded ? (<span className="block__default-due-date">{I18n.t('timeline.due_default')}</span>) : '';
    }

    let deleteBlock;
    let graded;
    if (isEditable) {
      if (!this.props.block.is_new) {
        deleteBlock = (<div className="delete-block-container"><button className="danger" onClick={this.deleteBlock}>Delete Block</button></div>);
      }
      className += ' editable';
      if (this.props.isDragging) { className += ' dragging'; }
      graded = (
        <Checkbox
          value={isGraded}
          onChange={this.updateGradeable}
          value_key={'gradeable'}
          editable={isEditable}
          label="Graded"
          container_class="graded"
        />
      );
    }

    let modules;
    if (this.props.block.training_modules || isEditable) {
      modules = (
        <TrainingModules
          onChange={this.passedUpdateBlock}
          all_modules={this.props.all_training_modules}
          block_modules={this.props.block.training_modules}
          editable={isEditable}
          block={this.props.block}
        />
      );
    }

    const content = (
      <div className="block__editor-container">
        <TextAreaInput
          onChange={this.updateBlock}
          value={this.props.block.content}
          value_key="content"
          editable={isEditable}
          rows="4"
          onFocus={this.props.toggleFocused}
          onBlur={this.props.toggleFocused}
          wysiwyg={true}
          className="block__block-content"
        />
        {modules}
      </div>
    );

    const dueDateSpacer = this.props.block.due_date ? (
      <span className="block__due-date-spacer"> - </span>
    ) : undefined;

    const editButton = this.props.editPermissions ? (
      <div className="block__edit-button-container">
        <button className="pull-right button ghost-button block__edit-block" onClick={this._setEditable}>Edit</button>
      </div>
    ) : undefined;

    let headerClass = 'block-title';
    if (isEditable) {
      headerClass += ' block-title--editing';
    }

    return (
      <li className={className}>
        {blockActions}
        {editButton}
        <div className="block__edit-container">
          <h4 className={headerClass}>
            <TextInput
              onChange={this.updateBlock}
              value={this.props.block.title}
              value_key="title"
              editable={isEditable}
              placeholder="Block title"
              show={Boolean(this.props.block.title) && !isEditable}
              className="title pull-left"
              spacer=""
              onFocus={this.props.toggleFocused}
              onBlur={this.props.toggleFocused}
            />
            <TextInput
              onChange={this.updateBlock}
              value={this.props.block.title}
              value_key={'title'}
              editable={isEditable}
              placeholder="Block title"
              label="Title"
              className="pull-left"
              spacer=""
              show={isEditable}
              onFocus={this.props.toggleFocused}
              onBlur={this.props.toggleFocused}
            />
          </h4>
          <div className={blockTypeClassName}>
            <BlockTypeSelect
              onChange={this.updateBlock}
              value={this.props.block.kind}
              value_key={'kind'}
              editable={isEditable}
              options={['In Class', 'Assignment', 'Milestone', 'Custom']}
              show={this.props.block.kind < 3 || isEditable}
            />
            {dueDateSpacer}
            {dueDateRead}
          </div>
        </div>
        <div className="block__edit-container">
          <div className="block__block-due-date">
            <DatePicker
              onChange={this.updateBlock}
              value={this.props.block.due_date}
              value_key="due_date"
              editable={isEditable}
              label="Due date"
              spacer=""
              placeholder="Due date"
              isClearable={true}
              show={isEditable && parseInt(this.props.block.kind) === 1}
              date_props={{ minDate: this.props.weekStart }}
              onFocus={this.props.toggleFocused}
              onBlur={this.props.toggleFocused}
            />
          </div>
          {graded}
        </div>
        {content}
        {deleteBlock}
      </li>
    );
  }
}
);


export default Block;
