import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { format } from 'date-fns';
import DatePicker from '../common/date_picker.jsx';
import { toDate } from '../../utils/date_utils';

// A block's stored due_date is optional. When it is blank, what that means
// depends on whether the block assigns training modules or exercises:
//  - with modules, every module still gets a due date, which falls back to the
//    end of the block's week (see BlockDateManager#default_due_date), so a
//    blank due_date means "use the default";
//  - without modules, nothing needs a date, so a blank due_date means
//    "no due date".
// The editor makes that choice explicit, shows what the default works out to,
// and lets a date that was set be removed again.
const hasModules = block => Boolean(block.training_module_ids && block.training_module_ids.length);

// Blocks that offer a due date: assignments, blocks that assign modules (whose
// rows show a due date), and any block that already has one stored, so a date
// left over from an earlier block type can still be seen and removed.
export const offersDueDate = block => Number(block.kind) === 1 || hasModules(block) || Boolean(block.due_date);

const formatDay = date => format(toDate(date), 'EEE, MMM d, yyyy');

const BlockDueDate = ({ block, updateBlock, weekStart, toggleFocused }) => {
  const [mode, setMode] = useState(block.due_date ? 'date' : 'blank');
  const withModules = hasModules(block);
  const name = `block-${block.id}-due-date-mode`;

  const chooseBlank = () => {
    setMode('blank');
    updateBlock('due_date', null);
  };

  const chooseDate = () => {
    setMode('date');
    // Start from the date the block falls back to, so choosing this
    // option never leaves the block without a date it can show.
    if (!block.due_date && block.default_due_date) {
      updateBlock('due_date', block.default_due_date);
    }
  };

  const blankLabel = withModules ? I18n.t('timeline.due_date_default') : I18n.t('timeline.due_date_none');
  const defaultDate = withModules && block.default_due_date ? (
    <span className="block__due-date-default-value"> ({formatDay(block.default_due_date)})</span>
  ) : null;

  return (
    <fieldset className="block__block-due-date">
      <legend>
        {I18n.t('timeline.due_date')}
        {withModules && (
          <small className="block__due-date-note">{I18n.t('timeline.due_date_modules_note')}</small>
        )}
      </legend>
      <div className="block__due-date-option">
        <label>
          <input type="radio" name={name} checked={mode === 'blank'} onChange={chooseBlank} />
          {blankLabel}{defaultDate}
        </label>
        {withModules && (
          <small className="block__due-date-help">{I18n.t('timeline.due_date_default_explanation')}</small>
        )}
      </div>
      <div className="block__due-date-option">
        <label>
          <input type="radio" name={name} checked={mode === 'date'} onChange={chooseDate} />
          {I18n.t('timeline.due_date_specific')}
        </label>
        {mode === 'date' && (
          <DatePicker
            key={block.due_date ? 'set' : 'unset'}
            onChange={updateBlock}
            value={block.due_date}
            value_key="due_date"
            editable={true}
            label={I18n.t('timeline.due_date')}
            spacer=""
            placeholder={I18n.t('timeline.due_date')}
            date_props={{ minDate: weekStart }}
            onFocus={toggleFocused}
            onBlur={toggleFocused}
          />
        )}
      </div>
    </fieldset>
  );
};

BlockDueDate.propTypes = {
  block: PropTypes.object.isRequired,
  updateBlock: PropTypes.func.isRequired,
  weekStart: PropTypes.object,
  toggleFocused: PropTypes.func
};

export default BlockDueDate;
