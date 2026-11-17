import React from 'react';

const t = (key, options) => I18n.t(`article_audit.${key}`, options);

// Shown, as a code, on a quote that QuoteValidator couldn't find in the article.
const QUOTE_NOT_FOUND = 'quote_not_found';

// Links a policy shortcut like "WP:V" or "MOS:LEAD" to English Wikipedia.
const policyUrl = shortcut => `https://en.wikipedia.org/wiki/${encodeURIComponent(shortcut.replace(/ /g, '_'))}`;

const CommentBody = ({ finding }) => {
  const { location = {} } = finding;
  const unverified = location.quote && location.quote_verified === false;
  // A quote anchored as text is already highlighted in the article; others
  // (wikitext, or anchored only to their section) are shown here.
  const showQuote = location.quote && finding.anchor !== 'text';

  return (
    <div className="article-audit-comment__body">
      <p className="article-audit-comment__context">
        {t(`categories.${finding.category}`)}
        {location.section && ` · ${location.section}`}
      </p>
      {showQuote && (
        <blockquote className="article-audit-comment__quote" aria-label={t('quote')}>
          {location.quote}
          {unverified && <code className="article-audit-comment__unverified">{QUOTE_NOT_FOUND}</code>}
        </blockquote>
      )}
      {finding.explanation && <p>{finding.explanation}</p>}
      {finding.details && (
        <dl className="article-audit-comment__details">
          {Object.entries(finding.details).map(([name, value]) => (
            <div key={name}><dt>{name}</dt><dd>{String(value)}</dd></div>
          ))}
        </dl>
      )}
      {finding.suggestion && (
        <div className="article-audit-comment__suggestion">
          <span className="article-audit-comment__label">{t('suggestion')}</span>
          <pre>{finding.suggestion}</pre>
        </div>
      )}
      <div className="article-audit-comment__meta">
        {finding.policy_refs?.map(ref => (
          <a key={ref} href={policyUrl(ref)} target="_blank" rel="noopener noreferrer">{ref}</a>
        ))}
        <code>{finding.check}</code>
      </div>
    </div>
  );
};

// One finding, as a comment beside the article. Collapsed, it shows the
// severity and title; selecting it shows the rest.
const CommentCard = ({ finding, selected, onSelect, top, cardRef }) => (
  <li
    ref={cardRef}
    className={`article-audit-comment article-audit-comment--${finding.severity}${selected ? ' article-audit-comment--selected' : ''}`}
    style={top === undefined ? undefined : { top }}
  >
    <button
      type="button"
      className="article-audit-comment__header"
      aria-expanded={selected}
      onClick={() => onSelect(finding.id)}
    >
      <span className={`article-audit-comment__severity article-audit-comment__severity--${finding.severity}`}>
        {t(`severities.${finding.severity}`)}
      </span>
      {finding.llm && <span className="article-audit__ai-label">{t('ai_label')}</span>}
      <span className="article-audit-comment__title">{finding.title || <code>{finding.code}</code>}</span>
    </button>
    {selected && <CommentBody finding={finding} />}
  </li>
);

export default CommentCard;
