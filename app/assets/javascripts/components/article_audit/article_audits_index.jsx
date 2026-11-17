import React, { useCallback, useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import request from '../../utils/request';

// Admin page: request an Article Audit for a page/revision URL and list recent
// audits. Visible strings live in the `article_audit` locale namespace.

const t = (key, options) => I18n.t(`article_audit.${key}`, options);

const ArticleAuditsIndex = () => {
  const [audits, setAudits] = useState(null);
  const [url, setUrl] = useState('');
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();

  const fetchAudits = useCallback(async () => {
    const response = await request('/article_audits.json');
    const data = await response.json();
    setAudits(data.audits);
  }, []);

  useEffect(() => { fetchAudits(); }, [fetchAudits]);

  const submit = async (event) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const response = await request('/article_audits', {
        method: 'POST',
        body: JSON.stringify({ url })
      });
      const data = await response.json();
      if (response.ok) {
        navigate(`/article_audits/${data.id}`);
      } else {
        setError(`${t('error')}: ${data.error}`);
      }
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="container article-audit">
      <h1>{t('heading')}</h1>

      <form className="article-audit__form" onSubmit={submit}>
        <label htmlFor="article-audit-url">{t('url_label')}</label>
        <input
          id="article-audit-url"
          type="text"
          value={url}
          onChange={e => setUrl(e.target.value)}
          placeholder="https://en.wikipedia.org/wiki/…"
        />
        <button type="submit" className="button dark" disabled={busy || !url.trim()}>
          {t('run_audit')}
        </button>
      </form>
      {error && <p className="article-audit__error" role="alert">{error}</p>}

      <h2>{t('recent_audits')}</h2>
      {!audits && <p>{t('loading')}</p>}
      {audits && (
        <table className="table table--small">
          <thead>
            <tr>
              <th>{t('article')}</th>
              <th>{t('wiki')}</th>
              <th>{t('status')}</th>
              <th>{t('requester')}</th>
              <th>{t('requested')}</th>
            </tr>
          </thead>
          <tbody>
            {audits.map(audit => (
              <tr key={audit.id}>
                <td>
                  <Link to={`/article_audits/${audit.id}`}>
                    {audit.article_title || audit.mw_rev_id}
                  </Link>
                </td>
                <td>{audit.wiki}</td>
                <td>
                  <span className={`article-audit__status article-audit__status--${audit.status}`}>
                    {t(`statuses.${audit.status}`)}
                  </span>
                </td>
                <td>{audit.requester}</td>
                <td>{new Date(audit.created_at).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
};

export default ArticleAuditsIndex;
