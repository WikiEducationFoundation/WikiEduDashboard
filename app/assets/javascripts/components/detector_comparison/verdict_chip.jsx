import React from 'react';
import PropTypes from 'prop-types';
import { formatScore } from './data';

// One detector's verdict on one text: its label, marked when the detector
// flagged the text, with the score beside it.
const VerdictChip = ({ verdict, showScore = false }) => {
  if (!verdict) return <span className="detector-comparison__none">–</span>;
  const modifier = verdict.flagged ? 'flagged' : 'clear';
  return (
    <span className="detector-comparison__verdict">
      <span className={`detector-comparison__chip detector-comparison__chip--${modifier}`}>{verdict.label || '?'}</span>
      {showScore && <span className="detector-comparison__score">{formatScore(verdict.score)}</span>}
    </span>
  );
};

VerdictChip.propTypes = {
  verdict: PropTypes.shape({ flagged: PropTypes.bool, label: PropTypes.string, score: PropTypes.number }),
  showScore: PropTypes.bool,
};

export default VerdictChip;
