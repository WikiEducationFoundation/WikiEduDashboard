import React from 'react';

const t = (key, options) => I18n.t(`article_audit.${key}`, options);

// Links a policy shortcut like "WP:V" or "MOS:LEAD" to English Wikipedia.
const policyUrl = shortcut => `https://en.wikipedia.org/wiki/${encodeURIComponent(shortcut.replace(/ /g, '_'))}`;

const FindingCard = ({ finding }) => {
  const { location = {} } = finding;
  const unverified = location.quote && location.quote_verified === false;

  return (
    <li className={`article-audit-finding article-audit-finding--${finding.severity}`}>
      <div className="article-audit-finding__header">
        <span className={`article-audit-finding__severity article-audit-finding__severity--${finding.severity}`}>
          {t(`severities.${finding.severity}`)}
        </span>
        <span className="article-audit-finding__title">{finding.title}</span>
        {location.section && <span className="article-audit-finding__section">{location.section}</span>}
      </div>
      {location.quote && (
        <blockquote className="article-audit-finding__quote" aria-label={t('quote')}>
          {location.quote}
          {unverified && <span className="article-audit-finding__unverified">{t('quote_not_found')}</span>}
        </blockquote>
      )}
      <p className="article-audit-finding__explanation">{finding.explanation}</p>
      {finding.suggestion && (
        <div className="article-audit-finding__suggestion">
          <span className="article-audit-finding__label">{t('suggestion')}</span>
          <pre>{finding.suggestion}</pre>
        </div>
      )}
      <div className="article-audit-finding__meta">
        {finding.policy_refs?.map(ref => (
          <a key={ref} href={policyUrl(ref)} target="_blank" rel="noopener noreferrer">{ref}</a>
        ))}
        <code>{finding.check}</code>
      </div>
    </li>
  );
};

export default FindingCard;
