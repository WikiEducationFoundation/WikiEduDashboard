import React, { useCallback, useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import request from '../../utils/request';
import AnnotatedArticle from './annotated_article.jsx';
import ArtifactView from './artifact_view.jsx';
import CheckResultsTable from './check_results_table.jsx';

// One Article Audit report, viewable by any signed-in user; admins also get
// the link back to the audit list and the re-run buttons. Polls while the
// audit is running.
// Visible strings live in the `article_audit` locale namespace.
//
// The Article tab shows the audited revision with the findings beside it as
// comments; Details has the checks' artifacts (source table, proposed
// categories and so on) and Checks has the per-check results.

const t = (key, options) => I18n.t(`article_audit.${key}`, options);

const POLL_MS = 4000;
const ACTIVE_STATUSES = ['queued', 'running'];
const SEVERITIES = ['must_fix', 'should_fix', 'suggestion', 'info'];
const TABS = ['article', 'details', 'checks'];

// All findings from the latest result of each check, marked with whether an
// LLM wrote them.
const allFindings = checkResults => checkResults.flatMap(result => result.findings.map(finding => ({ ...finding, llm: result.llm })));

// Counts by severity, each a toggle that shows or hides those findings.
const SeverityFilter = ({ findings, hidden, onToggle }) => (
  <div className="article-audit__legend">
    {SEVERITIES.map((severity) => {
      const count = findings.filter(finding => finding.severity === severity).length;
      return (
        <button
          key={severity}
          type="button"
          className={`article-audit__legend-item article-audit__legend-item--${severity}`}
          aria-pressed={!hidden.includes(severity)}
          onClick={() => onToggle(severity)}
        >
          <span className="article-audit__swatch" aria-hidden="true" />
          {t(`severities.${severity}`)} <span className="article-audit__count">{count}</span>
        </button>
      );
    })}
  </div>
);

const ArticleAuditReport = () => {
  const { id } = useParams();
  const [data, setData] = useState(null);
  const [tab, setTab] = useState('article');
  const [hidden, setHidden] = useState([]);

  const fetchReport = useCallback(async () => {
    const response = await request(`/article_audits/${id}.json`);
    setData(await response.json());
  }, [id]);

  useEffect(() => { fetchReport(); }, [fetchReport]);

  const active = data && ACTIVE_STATUSES.includes(data.audit.status);
  useEffect(() => {
    if (!active) return undefined;
    const interval = setInterval(fetchReport, POLL_MS);
    return () => clearInterval(interval);
  }, [active, fetchReport]);

  const rerun = async (checkKey) => {
    await request(`/article_audits/${id}/rerun_check`, {
      method: 'POST',
      body: JSON.stringify({ check_key: checkKey })
    });
    fetchReport();
  };

  const toggleSeverity = severity => setHidden(current => (
    current.includes(severity) ? current.filter(name => name !== severity) : [...current, severity]
  ));

  if (!data) return <div className="container"><p>{t('loading')}</p></div>;

  const { audit, admin, article_html: articleHtml, check_results: checkResults } = data;
  const findings = allFindings(checkResults);
  const withArtifacts = checkResults.filter(result => Object.keys(result.artifacts).length > 0);

  return (
    <div className="container article-audit article-audit--report">
      {admin && <p><Link to="/article_audits">{t('heading')}</Link></p>}
      <h1>{audit.article_title || audit.mw_rev_id}</h1>
      <p className="article-audit__meta">
        <span className={`article-audit__status article-audit__status--${audit.status}`} aria-live="polite">
          {t(`statuses.${audit.status}`)}
        </span>
        {' '}{audit.wiki} · {audit.mw_rev_id} · <a href={audit.revision_url} target="_blank" rel="noopener noreferrer">{t('view_revision')}</a>
      </p>
      <p className="article-audit__notice">{t('ai_notice')}</p>
      {audit.status === 'failed' && checkResults.length === 0 && (
        <p className="article-audit__error">{t('error')}: {audit.error}</p>
      )}

      <div className="article-audit__tabs" role="tablist">
        {TABS.map(name => (
          <button
            key={name}
            type="button"
            role="tab"
            id={`article-audit-tab-${name}`}
            aria-selected={tab === name}
            aria-controls={`article-audit-panel-${name}`}
            className="article-audit__tab"
            onClick={() => setTab(name)}
          >
            {t(`tabs.${name}`)}
          </button>
        ))}
      </div>

      <div role="tabpanel" id={`article-audit-panel-${tab}`} aria-labelledby={`article-audit-tab-${tab}`}>
        {tab === 'article' && (
          <>
            <SeverityFilter findings={findings} hidden={hidden} onToggle={toggleSeverity} />
            {!active && checkResults.length > 0 && findings.length === 0 && <p>{t('no_findings')}</p>}
            <AnnotatedArticle html={articleHtml} findings={findings} hiddenSeverities={hidden} />
          </>
        )}
        {tab === 'details' && withArtifacts.map(result => (
          <ArtifactView key={result.id} checkKey={result.check_key} artifacts={result.artifacts} llm={result.llm} />
        ))}
        {tab === 'checks' && checkResults.length > 0 && (
          <CheckResultsTable results={checkResults} onRerun={admin ? rerun : null} rerunDisabled={active} />
        )}
      </div>
    </div>
  );
};

export default ArticleAuditReport;
