import React, { useState } from 'react';
import request from '../../utils/request';

const t = (key, options) => I18n.t(`article_audit.feedback.${key}`, options);

// Each question's answers; the locale has a label for each under
// article_audit.feedback.<question>_options.
export const QUESTIONS = {
  accurate: ['yes', 'partly', 'no'],
  show_to_participants: ['yes', 'maybe', 'no']
};
const FIELDS = Object.keys(QUESTIONS).flatMap(name => [name, `${name}_comment`]);

const unchanged = (values, saved) => FIELDS.every(field => (values[field] || '') === (saved[field] || ''));

// One question as radios, with an optional comment.
const FeedbackQuestion = ({ name, findingId, values, onChange }) => (
  <fieldset className="article-audit-feedback__question">
    <legend>{t(`${name}_question`)}</legend>
    <div className="article-audit-feedback__options">
      {QUESTIONS[name].map(option => (
        <label key={option}>
          <input
            type="radio"
            name={`${name}-${findingId}`}
            value={option}
            checked={values[name] === option}
            onChange={() => onChange(name, option)}
          />
          {t(`${name}_options.${option}`)}
        </label>
      ))}
    </div>
    <label className="article-audit-feedback__comment">
      {t('comment')}
      <textarea
        rows={2}
        value={values[`${name}_comment`] || ''}
        onChange={event => onChange(`${name}_comment`, event.target.value)}
      />
    </label>
  </fieldset>
);

// The current user's evaluation of a finding, saved with the report's
// finding_feedback action. Starts from what they saved before, if anything.
const FindingFeedback = ({ auditId, finding }) => {
  const [saved, setSaved] = useState(finding.feedback || {});
  const [values, setValues] = useState(finding.feedback || {});
  const [status, setStatus] = useState(null);
  const clean = unchanged(values, saved);

  const onChange = (field, value) => {
    setValues(current => ({ ...current, [field]: value }));
    setStatus(null);
  };

  const save = async (event) => {
    event.preventDefault();
    setStatus('saving');
    const [checkResultId, findingIndex] = finding.id.split('-');
    const response = await request(`/article_audits/${auditId}/finding_feedback`, {
      method: 'PUT',
      body: JSON.stringify({ ...values, check_result_id: checkResultId, finding_index: findingIndex })
    });
    if (!response.ok) {
      setStatus('error');
      return;
    }
    const data = await response.json();
    setSaved(data);
    setValues(data);
    setStatus('saved');
  };

  return (
    <form className="article-audit-feedback" onSubmit={save}>
      {Object.keys(QUESTIONS).map(name => (
        <FeedbackQuestion key={name} name={name} findingId={finding.id} values={values} onChange={onChange} />
      ))}
      <div className="article-audit-feedback__actions">
        <button type="submit" className="button small" disabled={clean || status === 'saving'}>
          {t('save')}
        </button>
        <span className="article-audit-feedback__status" role="status">
          {status === 'saved' && t('saved')}
          {status === 'error' && <span className="article-audit__error">{I18n.t('article_audit.error')}</span>}
        </span>
      </div>
    </form>
  );
};

export default FindingFeedback;
