import React, { useRef } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import TextInput from '../common/text_input.jsx';
import TextAreaInput from '../common/text_area_input.jsx';
import TrainingModules from './TrainingModules/TrainingModules';
import BlockTypeSelect from './block_type_select.jsx';
import BlockDueDate, { offersDueDate } from './BlockDueDate.jsx';
import TrainingModulesViewMode from './TrainingModules/TrainingModulesViewMode.jsx';
import { BLOCK_KIND_RESOURCES } from '../../constants';
import { initiateConfirm } from '../../actions/confirm_actions.js';

const Block = (props) => {
  // Once a block has shown a due date, keep offering the control, so that
  // removing the date doesn't also remove the control mid-edit.
  const hadDueDate = useRef(false);
  hadDueDate.current = hadDueDate.current || Boolean(props.block.due_date);

const updateBlock = (valueKey, value) => {
    const toPass = { ...props.block };
    toPass[valueKey] = value;
    delete toPass.deleteBlock;
    return props.updateBlock(toPass);
  };

  const passedUpdateBlock = (selectedIds) => {
    const newBlock = Object.assign({}, props.block);
    newBlock.training_module_ids = selectedIds;
    return props.updateBlock(newBlock);
  };

  const deleteBlocks = () => {
    const confirmMessage = 'Are you sure you want to delete this block? This will delete the block and all of its content.\n\nThis cannot be undone.';
    const deleteBlock = props.deleteBlock;
    const onConfirm = () => deleteBlock(props.block.id);
    return props.initiateConfirm({ confirmMessage, onConfirm });
  };

  const _setEditable = () => {
    return props.setBlockEditable(props.block.id);
  };

  const _isEditable = () => {
    if (props.editableBlockIds) {
      return props.editableBlockIds.indexOf(props.block.id) >= 0;
    }
    return false;
  };

  const _hidden = () => {
    // Resources blocks are hidden on the timeline, except for instructors and admins.
    // They show up in the Resources tab instead, where there is no Week and so no weekStart.
    return props.weekStart && !props.editPermissions && props.block.kind === BLOCK_KIND_RESOURCES;
  };

    const block = props.block;
    const isEditable = _isEditable();
    const isStudent = props.current_user && props.current_user.isStudent;
    const isStaff = Boolean(props.current_user && props.current_user.isAdvancedRole);
    if (_hidden()) { return null; }

    let className = 'block';
    className += ` block-kind-${block.kind}`;

    let blockTypeClassName = 'block__block-type';
    if (props.editPermissions) {
      blockTypeClassName += ' editable';
    }

    let blockActions;
    if (isEditable) {
      blockActions = (
        <div className="float-container block__block-actions">
          <button type="button" onClick={props.saveBlockChanges.bind(null, block.id)} className="button dark pull-right no-clear">Save</button>
          <span
            role="button"
            tabIndex={0}
            onClick={props.cancelBlockEditable.bind(null, block.id)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                props.cancelBlockEditable(block.id);
              }
            }}
            className="span-link pull-right no-clear"
          >Cancel</span>
        </div>
      );
    }

    let dueDateRead;
    // A date set on any kind of block applies to its modules, so show it.
    if (block.due_date) {
      dueDateRead = (
        <TextInput
          onChange={updateBlock}
          value={block.due_date}
          value_key={'due_date'}
          editable={false}
          label="Due"
          show={Boolean(block.due_date)}
          onFocus={props.toggleFocused}
          onBlur={props.toggleFocused}
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
        deleteBlock = (<div className="delete-block-container"><button type="button" className="danger" onClick={deleteBlocks}>Delete Block</button></div>);
      }
      className += ' editable';
      if (props.isDragging) { className += ' dragging'; }
    }

    let modules = [];
    if (block.training_modules) {
      if (isEditable) {
        const length = block.training_modules.length;
        modules.push(<TrainingModules
          all_modules={props.all_training_modules}
          block_modules={block.training_modules}
          block={block}
          editable={isEditable}
          header={length > 1 && 'Training'}
          key=""
          onChange={passedUpdateBlock}
          trainingLibrarySlug={props.trainingLibrarySlug}
        />);
      } else {
        modules = (<TrainingModulesViewMode
          all_modules={props.all_training_modules}
          block={block}
          editable={isEditable}
          isStudent={isStudent}
          isStaff={isStaff}
          trainingLibrarySlug={props.trainingLibrarySlug}
        />);
      }
    } else {
      modules.push(<TrainingModules
        all_modules={props.all_training_modules}
        block_modules={[]}
        block={block}
        editable={isEditable}
        header={length > 1 && 'Training'}
        key="training-modules"
        onChange={passedUpdateBlock}
        trainingLibrarySlug={props.trainingLibrarySlug}
      />);
    }

    const content = (
      <div className="block__editor-container">
        {modules}
        <TextAreaInput
          onChange={updateBlock}
          value={block.content}
          value_key="content"
          editable={isEditable}
          rows="4"
          onFocus={props.toggleFocused}
          onBlur={props.toggleFocused}
          wysiwyg={true}
          className="block__block-content"
        />

      </div>
    );

    const dueDateSpacer = block.due_date ? (
      <span className="block__due-date-spacer"> - </span>
    ) : undefined;

    const editButton = props.editPermissions ? (
      <div className="block__edit-button-container">
        <button type="button" className="pull-right button ghost-button block__edit-block" onClick={_setEditable}>{I18n.t('editable.edit')}</button>
      </div>
    ) : undefined;

    let headerClass = 'block-title';
    if (isEditable) {
      headerClass += ' block-title--editing';
    }

    return (
      <li className={className} id={`block-${block.id}`}>
        {blockActions}
        {editButton}
        <div className="block__edit-container">
          <h3 className={headerClass}>
            <TextInput
              onChange={updateBlock}
              value={block.title}
              value_key="title"
              editable={isEditable}
              placeholder="Block title"
              show={Boolean(block.title) && !isEditable}
              className="title pull-left"
              spacer=""
              onFocus={props.toggleFocused}
              onBlur={props.toggleFocused}
            />
            <TextInput
              onChange={updateBlock}
              value={block.title}
              value_key={'title'}
              editable={isEditable}
              placeholder="Block title"
              label="Title"
              className="pull-left"
              spacer=""
              show={isEditable}
              onFocus={props.toggleFocused}
              onBlur={props.toggleFocused}
            />
          </h3>
          <div className={blockTypeClassName}>
            <BlockTypeSelect
              onChange={updateBlock}
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
          {isEditable && (offersDueDate(block) || hadDueDate.current) && (
            <BlockDueDate
              block={block}
              updateBlock={updateBlock}
              weekStart={props.weekStart}
              toggleFocused={props.toggleFocused}
            />
          )}
          {blockKindNote}
        </div>
        {content}
        {deleteBlock}
      </li>
    );
  };
Block.displayName = 'Block';

Block.propTypes = {
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
  };
const mapDispatchToProps = { initiateConfirm };

export default connect(null, mapDispatchToProps)(
  Block
);
