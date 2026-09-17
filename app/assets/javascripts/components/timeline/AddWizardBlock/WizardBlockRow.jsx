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

  // Forty-odd rows each end in a button that just says "Add". The accessible
  // name is composed from the button and the block title so that a screen
  // reader's button list is not forty copies of the same word, and the meta
  // line and conditions are attached as its description so the match state,
  // and what tells apart two variants of the same title, are read after it.
  const titleId = `wizard-block-${entry.id}-title`;
  const metaId = `wizard-block-${entry.id}-meta`;
  const buttonId = `wizard-block-${entry.id}-add`;
  const conditionsId = `wizard-block-${entry.id}-conditions`;

  // The spaces between the spans are deliberate: CSS margins separate them
  // visually, but adjacent inline elements with no whitespace between them are
  // read by a screen reader as one run-on word.
  return (
    <li className={`wizard-block-row wizard-block-row--${entry.match}`} data-catalog-id={entry.id}>
      <div className="wizard-block-row__main">
        <h4 className="wizard-block-row__title" id={titleId}>{entry.title}</h4>
        <p className="wizard-block-row__meta" id={metaId}>
          <span className="wizard-block-row__kind">{kind}</span>
          {' '}
          <span className={`wizard-block-row__match wizard-block-row__match--${entry.match}`}>
            {MATCH_LABELS[entry.match]()}
          </span>
          {entry.in_timeline && (
            <>
              {' '}
              <span className="wizard-block-row__badge">
                {I18n.t('timeline.standard_block_already_added')}
              </span>
            </>
          )}
        </p>
        {conditions && (
          <p className="wizard-block-row__conditions" id={conditionsId}>{conditions}</p>
        )}
      </div>
      <button
        type="button"
        id={buttonId}
        className="button border wizard-block-row__add"
        disabled={!entry.insertable}
        onClick={() => onAdd(entry)}
        aria-labelledby={`${buttonId} ${titleId}`}
        aria-describedby={conditions ? `${metaId} ${conditionsId}` : metaId}
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
