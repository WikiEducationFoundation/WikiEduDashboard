import React from 'react';

const t = (key, options) => I18n.t(`article_audit.${key}`, options);

// Renders a check's artifacts (structured output that isn't a finding, such
// as a proposed short description or a table of sources) generically: strings
// as text, objects as label/value lists (recursively), arrays of objects as
// tables, and anything else as JSON.

const isRecordList = value => Array.isArray(value) && value.length > 0
  && value.every(item => item && typeof item === 'object' && !Array.isArray(item));

const isScalar = value => value === null || ['string', 'number', 'boolean'].includes(typeof value);

const cellText = value => (typeof value === 'object' && value !== null ? JSON.stringify(value) : String(value ?? ''));

const isLink = value => typeof value === 'string' && /^https?:\/\//.test(value);

const ScalarValue = ({ value }) => (
  isLink(value) ? <a href={value} target="_blank" rel="noopener noreferrer">{value}</a> : cellText(value)
);

// URLs are links, and may break anywhere, since they have no spaces to
// wrap at.
const RecordTable = ({ records }) => {
  const columns = [...new Set(records.flatMap(Object.keys))];
  return (
    <table className="table table--small">
      <thead>
        <tr>{columns.map(column => <th key={column}>{column}</th>)}</tr>
      </thead>
      <tbody>
        {records.map((record, index) => (
          <tr key={index}>
            {columns.map(column => (
              <td key={column} className={isLink(record[column]) ? 'article-audit-artifact__url' : undefined}>
                <ScalarValue value={record[column]} />
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
};

const isPlainObject = value => value && typeof value === 'object' && !Array.isArray(value);

// An object, such as a notability assessment, as label/value pairs; values
// that are themselves lists or objects render recursively.
const FieldList = ({ fields }) => (
  <dl className="article-audit-artifact__fields">
    {Object.entries(fields).map(([name, value]) => (
      <React.Fragment key={name}>
        <dt>{name}</dt>
        <dd>{isScalar(value) ? <ScalarValue value={value} /> : <ArtifactValue value={value} />}</dd>
      </React.Fragment>
    ))}
  </dl>
);

const ArtifactValue = ({ value }) => {
  if (typeof value === 'string') return <p>{value}</p>;
  if (isPlainObject(value)) return <FieldList fields={value} />;
  if (isRecordList(value)) return <RecordTable records={value} />;
  if (Array.isArray(value) && value.every(item => typeof item === 'string')) {
    return <ul>{value.map(item => <li key={item}>{item}</li>)}</ul>;
  }
  if (Array.isArray(value) && value.length === 0) return <p>—</p>;
  return <pre>{JSON.stringify(value, null, 2)}</pre>;
};

const ArtifactView = ({ checkKey, artifacts, llm }) => (
  <section className="article-audit-artifact">
    <h3><code>{checkKey}</code>{llm && <span className="article-audit__ai-label">{t('ai_label')}</span>}</h3>
    {Object.entries(artifacts).map(([name, value]) => (
      <div key={name}>
        <h4>{name}</h4>
        <ArtifactValue value={value} />
      </div>
    ))}
  </section>
);

export default ArtifactView;
