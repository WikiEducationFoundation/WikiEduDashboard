import React from 'react';

const t = (key, options) => I18n.t(`article_audit.${key}`, options);

const tokenSummary = (usage) => {
  if (!usage || usage.input_tokens === undefined) return '—';
  const cached = usage.cache_read_input_tokens ? ` (${usage.cache_read_input_tokens} cached)` : '';
  return `${usage.input_tokens} in${cached} / ${usage.output_tokens} out`;
};

const duration = ms => (ms ? `${(ms / 1000).toFixed(1)}s` : '—');

// Per-check run details for evaluating the audit itself: which engine and
// prompt version produced each result, what it cost, and, when onRerun is
// given, a re-run button.
const CheckResultsTable = ({ results, onRerun, rerunDisabled }) => (
  <table className="table table--small article-audit__checks">
    <thead>
      <tr>
        <th>{t('check')}</th>
        <th>{t('status')}</th>
        <th>{t('engine')}</th>
        <th>{t('version')}</th>
        <th>{t('tokens')}</th>
        <th>{t('duration')}</th>
        <th>{t('runs')}</th>
        {onRerun && <th><span className="sr-only">{t('rerun')}</span></th>}
      </tr>
    </thead>
    <tbody>
      {results.map(result => (
        <tr key={result.id}>
          <td>
            <code>{result.check_key}</code>
            <div><small>{t('findings_count', { count: result.findings.length })}</small></div>
            {result.error && <div className="article-audit__error"><small>{result.error}</small></div>}
          </td>
          <td>{result.status}</td>
          <td><small>{result.engine}</small></td>
          <td><small>{result.check_version}</small></td>
          <td><small>{tokenSummary(result.usage)}</small></td>
          <td>{duration(result.duration_ms)}</td>
          <td className="article-audit__runs">{result.run_count}</td>
          {onRerun && (
            <td>
              <button className="button small" disabled={rerunDisabled} onClick={() => onRerun(result.check_key)}>
                {t('rerun')}
              </button>
            </td>
          )}
        </tr>
      ))}
    </tbody>
  </table>
);

export default CheckResultsTable;
