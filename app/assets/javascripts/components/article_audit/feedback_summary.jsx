import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import request from '../../utils/request';
import { QUESTIONS } from './finding_feedback.jsx';

// Admin page: everyone's feedback on Article Audit findings, tallied by check
// (and by finding code, for findings from code), then each response in full.
// Used to decide which kinds of finding to show participants by default.

const t = (key, options) => I18n.t(`article_audit.${key}`, options);
const question = name => t(`feedback.${name}_question`);
const answer = (name, option) => (option ? t(`feedback.${name}_options.${option}`) : '—');

const Tallies = ({ groups }) => (
  <table className="table table--small article-audit-feedback-summary__tallies">
    <thead>
      <tr>
        <th rowSpan={2} scope="col" className="article-audit-feedback-summary__check">{t('check')}</th>
        <th rowSpan={2} scope="col">{t('feedback.responses')}</th>
        {Object.entries(QUESTIONS).map(([name, options]) => (
          <th key={name} colSpan={options.length} scope="colgroup">{question(name)}</th>
        ))}
      </tr>
      <tr>
        {Object.entries(QUESTIONS).flatMap(([name, options]) => options.map(option => (
          <th key={`${name}-${option}`} scope="col">{answer(name, option)}</th>
        )))}
      </tr>
    </thead>
    <tbody>
      {groups.map(group => (
        <tr key={`${group.check_key} ${group.code}`}>
          <td className="article-audit-feedback-summary__check">
            <code>{group.check_key}</code>
            {group.code && <div><small><code>{group.code}</code></small></div>}
          </td>
          <td>{group.responses}</td>
          {Object.entries(QUESTIONS).flatMap(([name, options]) => options.map(option => (
            <td key={`${name}-${option}`}>{group[name][option]}</td>
          )))}
        </tr>
      ))}
    </tbody>
  </table>
);

const Answer = ({ name, response }) => (
  <>
    {answer(name, response[name])}
    {response[`${name}_comment`] && (
      <p className="article-audit-feedback-summary__comment">{response[`${name}_comment`]}</p>
    )}
  </>
);

const Responses = ({ responses }) => (
  <table className="table table--small article-audit-feedback-summary__responses">
    <thead>
      <tr>
        <th>{t('feedback.finding')}</th>
        <th>{t('feedback.severity')}</th>
        {Object.keys(QUESTIONS).map(name => <th key={name}>{question(name)}</th>)}
        <th>{t('feedback.user')}</th>
      </tr>
    </thead>
    <tbody>
      {responses.map(response => (
        <tr key={`${response.finding_id} ${response.user}`}>
          <td>
            <Link to={`/article_audits/${response.audit_id}`}>
              {response.title || <code>{response.code}</code>}
            </Link>
            <div><small>{response.article_title} · <code>{response.check_key}</code></small></div>
          </td>
          <td>{response.severity && t(`severities.${response.severity}`)}</td>
          {Object.keys(QUESTIONS).map(name => <td key={name}><Answer name={name} response={response} /></td>)}
          <td>
            {response.user}
            <div><small>{new Date(response.updated_at).toLocaleString()}</small></div>
          </td>
        </tr>
      ))}
    </tbody>
  </table>
);

const FeedbackSummary = () => {
  const [data, setData] = useState(null);

  useEffect(() => {
    (async () => {
      const response = await request('/article_audits/feedback.json');
      setData(await response.json());
    })();
  }, []);

  return (
    <div className="container article-audit article-audit-feedback-summary">
      <p><Link to="/article_audits">{t('heading')}</Link></p>
      <h1>{t('feedback.heading')}</h1>
      {!data && <p>{t('loading')}</p>}
      {data && (
        <>
          <Tallies groups={data.groups} />
          <h2>{t('feedback.responses')}</h2>
          <Responses responses={data.responses} />
        </>
      )}
    </div>
  );
};

export default FeedbackSummary;
