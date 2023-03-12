import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import TextInput from '../common/text_input.jsx';
import DatePicker from '../common/date_picker.jsx';
import TextAreaInput from '../common/text_area_input.jsx';
import TrainingModules from './TrainingModules/TrainingModules';
import BlockTypeSelect from './block_type_select.jsx';
import TrainingModulesViewMode from './TrainingModules/TrainingModulesViewMode.jsx';
import { BLOCK_KIND_RESOURCES } from '../../constants';
import { initiateConfirm } from '../../actions/confirm_actions.js';

const DEFAULT_POINTS = 10;

const Block = createReactClass({
  displayName: 'Block',

  propTypes: {
    block: PropTypes.object,
    editableBlockIds: PropTypes.array,
    editPermissions: PropTypes.bool,
    saveBlockChanges: PropTypes.func,
    cancelBlockEditable: PropTypes.func,
    updateBlock: PropTypes.func,
    toggleFocused: PropTypes.func,
    isDragging: PropTypes.bool,
    all_training_modules: PropTypes.array,
    weekStart: PropTypes.object,
    trainingLibrarySlug: PropTypes.string.isRequired,
    current_user: PropTypes.object,
    initiateConfirm: PropTypes.func.isRequired
  },

  updateBlock(valueKey, value) {
    const toPass = { ...this.props.block };
    toPass[valueKey] = value;
    delete toPass.deleteBlock;
    return this.props.updateBlock(toPass);
  },

  passedUpdateBlock(selectedIds) {
    const newBlock = Object.assign({}, this.props.block);
    newBlock.training_module_ids = selectedIds;
    return this.props.updateBlock(newBlock);
  },

  deleteBlock() {
    const confirmMessage = 'Are you sure you want to delete this block? This will delete the block and all of its content.\n\nThis cannot be undone.';
    const deleteBlock = this.props.deleteBlock;
    const onConfirm = () => deleteBlock(this.props.block.id);
    return this.props.initiateConfirm({ confirmMessage, onConfirm });
  },

  _setEditable() {
    return this.props.setBlockEditable(this.props.block.id);
  },

  _isEditable() {
    if (this.props.editableBlockIds) {
      return this.props.editableBlockIds.indexOf(this.props.block.id) >= 0;
    }
    return false;
  },

  _hidden() {
    // Resources blocks are hidden on the timeline, except for instructors and admins.
    // They show up in the Resources tab instead, where there is no Week and so no weekStart.
    return this.props.weekStart && !this.props.editPermissions && this.props.block.kind === BLOCK_KIND_RESOURCES;
  },

  updateGradeable(_valueKey, value) {
    if (value) {
      this.updateBlock('points', DEFAULT_POINTS);
    } else {
      this.updateBlock('points', null);
    }
  },

  render() {
    const block = this.props.block;
    const isEditable = this._isEditable();
    const isStudent = this.props.current_user && this.props.current_user.isStudent;
    if (this._hidden()) { return null; }

    let className = 'block';
    className += ` block-kind-${block.kind}`;

    let blockTypeClassName = 'block__block-type';
    if (this.props.editPermissions) {
      blockTypeClassName += ' editable';
    }

    let blockActions;
    if (isEditable) {
      blockActions = (
        <div className="float-container block__block-actions">
          <button onClick={this.props.saveBlockChanges.bind(null, block.id)} className="button dark pull-right no-clear">Save</button>
          <span role="button" tabIndex={0} onClick={this.props.cancelBlockEditable.bind(null, block.id)} className="span-link pull-right no-clear">Cancel</span>
        </div>
      );
    }

    let dueDateRead;
    if (block.due_date !== null && block.kind === 1) {
      dueDateRead = (
        <TextInput
          onChange={this.updateBlock}
          value={block.due_date}
          value_key={'due_date'}
          editable={false}
          label="Due"
          show={Boolean(block.due_date)}
          onFocus={this.props.toggleFocused}
          onBlur={this.props.toggleFocused}
          p_tag_classname="block__read__due-date"
        />
      );
    }

    let blockKindNote;
    if (block.kind === BLOCK_KIND_RESOURCES && isEditable) {
      blockKindNote = <small>This block will be included on the Resources tab. It will not appear on the Timeline for students.</small>;
    }

    let deleteBlock;
    // let graded;
    if (isEditable) {
      if (!block.is_new) {
        deleteBlock = (<div className="delete-block-container"><button className="danger" onClick={this.deleteBlock}>Delete Block</button></div>);
      }
      className += ' editable';
      if (this.props.isDragging) { className += ' dragging'; }
    }

    let modules = [];
    if (block.training_modules) {
      if (isEditable) {
        const length = block.training_modules.length;
        modules.push(<TrainingModules
          all_modules={this.props.all_training_modules}
          block_modules={block.training_modules}
          block={block}
          editable={isEditable}
          header={length > 1 && 'Training'}
          key=""
          onChange={this.passedUpdateBlock}
          trainingLibrarySlug={this.props.trainingLibrarySlug}
        />);
      } else {
        modules = (<TrainingModulesViewMode
          all_modules={this.props.all_training_modules}
          block={block}
          editable={isEditable}
          isStudent={isStudent}
          trainingLibrarySlug={this.props.trainingLibrarySlug}
        />);
      }
    } else {
      modules.push(<TrainingModules
        all_modules={this.props.all_training_modules}
        block_modules={[]}
        block={block}
        editable={isEditable}
        header={length > 1 && 'Training'}
        key="training-modules"
        onChange={this.passedUpdateBlock}
        trainingLibrarySlug={this.props.trainingLibrarySlug}
      />);
    }

    const content = (
      <div className="block__editor-container">
        {modules}
        <TextAreaInput
          onChange={this.updateBlock}
          value={block.content}
          value_key="content"
          editable={isEditable}
          rows="4"
          onFocus={this.props.toggleFocused}
          onBlur={this.props.toggleFocused}
          wysiwyg={true}
          className="block__block-content"
        />

      </div>
    );

    const dueDateSpacer = block.due_date && block.kind === 1 ? (
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
          <h3 className={headerClass}>
            <TextInput
              onChange={this.updateBlock}
              value={block.title}
              value_key="title"
              editable={isEditable}
              placeholder="Block title"
              show={Boolean(block.title) && !isEditable}
              className="title pull-left"
              spacer=""
              onFocus={this.props.toggleFocused}
              onBlur={this.props.toggleFocused}
            />
            <TextInput
              onChange={this.updateBlock}
              value={block.title}
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
          </h3>
          <div className={blockTypeClassName}>
            <BlockTypeSelect
              onChange={this.updateBlock}
              value={block.kind}
              value_key={'kind'}
              editable={isEditable}
              show={block.kind < 3 || isEditable}
            />
            {dueDateSpacer}
            {dueDateRead}
          </div>
        </div>
        <div className="block__edit-container">
          <div className="block__block-due-date">
            <DatePicker
              onChange={this.updateBlock}
              value={block.due_date}
              value_key="due_date"
              editable={isEditable}
              label="Due date"
              spacer=""
              placeholder="Due date"
              isClearable={true}
              show={isEditable && parseInt(block.kind) === 1}
              date_props={{ minDate: this.props.weekStart }}
              onFocus={this.props.toggleFocused}
              onBlur={this.props.toggleFocused}
            />
          </div>
          {blockKindNote}
        </div>
        {content}
        {deleteBlock}
      </li>
    );
  }
}
);

const mapDispatchToProps = { initiateConfirm };

export default connect(null, mapDispatchToProps)(
  // Expandable(Block)
  Block
);
// export default Block;
