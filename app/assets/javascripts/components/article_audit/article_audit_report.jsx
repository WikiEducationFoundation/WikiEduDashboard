import React, { useCallback, useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import request from '../../utils/request';
import FindingCard from './finding_card.jsx';
import ArtifactView from './artifact_view.jsx';
import CheckResultsTable from './check_results_table.jsx';

// Admin page: one Article Audit report. Polls while the audit is running.
// Visible strings live in the `article_audit` locale namespace.

const t = (key, options) => I18n.t(`article_audit.${key}`, options);

const POLL_MS = 4000;
const ACTIVE_STATUSES = ['queued', 'running'];
const CATEGORY_ORDER = ['sourcing', 'policy', 'tone', 'structure', 'new_article', 'infobox', 'links', 'mos', 'external'];
const SEVERITY_ORDER = ['must_fix', 'should_fix', 'suggestion', 'info'];

const byOrder = (order, value) => {
  const index = order.indexOf(value);
  return index === -1 ? order.length : index;
};

// All findings from the latest result of each check, grouped by category and
// sorted most severe first.
const groupFindings = (checkResults) => {
  const findings = checkResults.flatMap(result => result.findings);
  const groups = {};
  findings.forEach((finding) => {
    (groups[finding.category] ||= []).push(finding);
  });
  return Object.keys(groups)
    .sort((a, b) => byOrder(CATEGORY_ORDER, a) - byOrder(CATEGORY_ORDER, b))
    .map(category => ({
      category,
      findings: groups[category].sort((a, b) => byOrder(SEVERITY_ORDER, a.severity) - byOrder(SEVERITY_ORDER, b.severity))
    }));
};

const ArticleAuditReport = () => {
  const { id } = useParams();
  const [data, setData] = useState(null);

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

  if (!data) return <div className="container"><p>{t('loading')}</p></div>;

  const { audit, check_results: checkResults } = data;
  const groups = groupFindings(checkResults);
  const withArtifacts = checkResults.filter(result => Object.keys(result.artifacts).length > 0);

  return (
    <div className="container article-audit">
      <p><Link to="/article_audits">{t('heading')}</Link></p>
      <h1>{audit.article_title || audit.mw_rev_id}</h1>
      <p className="article-audit__meta">
        <span className={`article-audit__status article-audit__status--${audit.status}`}>
          {t(`statuses.${audit.status}`)}
        </span>
        {' '}{audit.wiki} · {audit.mw_rev_id} · <a href={audit.revision_url} target="_blank" rel="noopener noreferrer">{t('view_revision')}</a>
      </p>
      <p className="article-audit__notice">{t('ai_notice')}</p>
      {active && <p className="article-audit__notice" aria-live="polite">{t('running_notice')}</p>}
      {audit.status === 'failed' && checkResults.length === 0 && (
        <p className="article-audit__error">{t('failed_notice')} {audit.error}</p>
      )}

      {groups.map(group => (
        <section key={group.category} className="article-audit__category">
          <h2>{t(`categories.${group.category}`)} <small>{t('findings_count', { count: group.findings.length })}</small></h2>
          <ul className="article-audit__findings">
            {group.findings.map((finding, index) => <FindingCard key={index} finding={finding} />)}
          </ul>
        </section>
      ))}
      {!active && checkResults.length > 0 && groups.length === 0 && <p>{t('no_findings')}</p>}

      {withArtifacts.map(result => (
        <ArtifactView key={result.id} checkKey={result.check_key} artifacts={result.artifacts} />
      ))}

      {checkResults.length > 0 && (
        <CheckResultsTable results={checkResults} onRerun={rerun} rerunDisabled={active} />
      )}
    </div>
  );
};

export default ArticleAuditReport;
