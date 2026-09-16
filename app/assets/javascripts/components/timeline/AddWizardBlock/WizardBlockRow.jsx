import React from 'react';
import PropTypes from 'prop-types';
import { KINDS } from '../block_type_select.jsx';

// How an entry's conditions relate to this course. 'unknown' is not a failure:
// the wizard never persisted the answer that block depends on, so nothing can
// be said either way (see WizardLogicState).
const MATCH_LABELS = {
  yes: () => I18n.t('timeline.standard_block_matches'),
  no: () => I18n.t('timeline.standard_block_does_not_match'),
  unknown: () => I18n.t('timeline.standard_block_match_unknown')
};

const conditionText = (conditions) => {
  const parts = [];
  if (conditions.if.length) parts.push(`if: ${conditions.if.join(', ')}`);
  if (conditions.unless.length) parts.push(`unless: ${conditions.unless.join(', ')}`);
  return parts.join(' · ');
};

const WizardBlockRow = ({ entry, onAdd }) => {
  const conditions = conditionText(entry.conditions);
  const kind = KINDS[entry.kind] || KINDS[0];

  return (
    <li className={`wizard-block-row wizard-block-row--${entry.match}`} data-catalog-id={entry.id}>
      <div className="wizard-block-row__main">
        <h4 className="wizard-block-row__title">{entry.title}</h4>
        <p className="wizard-block-row__meta">
          <span className="wizard-block-row__kind">{kind}</span>
          <span className={`wizard-block-row__match wizard-block-row__match--${entry.match}`}>
            {MATCH_LABELS[entry.match]()}
          </span>
          {entry.in_timeline && (
            <span className="wizard-block-row__badge">
              {I18n.t('timeline.standard_block_already_added')}
            </span>
          )}
        </p>
        {conditions && <p className="wizard-block-row__conditions">{conditions}</p>}
      </div>
      <button
        type="button"
        className="button border wizard-block-row__add"
        disabled={!entry.insertable}
        onClick={() => onAdd(entry)}
      >
        {I18n.t('timeline.standard_block_add')}
      </button>
    </li>
  );
};

WizardBlockRow.propTypes = {
  entry: PropTypes.object.isRequired,
  onAdd: PropTypes.func.isRequired
};

export default WizardBlockRow;
