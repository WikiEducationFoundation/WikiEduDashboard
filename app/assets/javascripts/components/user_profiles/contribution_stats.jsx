import React, { useState, useEffect, useMemo } from 'react';
import PropTypes from 'prop-types';
import InstructorStats from './instructor_stats.jsx';
import StudentStats from './student_stats.jsx';
import DropdownSortSelect from '../common/dropdown_sort_select';
import ProfileDownloadButtons from './profile_download_buttons.jsx';

const defaultParams = {
  wiki: 'all'
};

const getSearchParam = (key, fallback) => {
  if (typeof window === 'undefined') return fallback;
  return new URLSearchParams(window.location.search).get(key) || fallback;
};

const wikiValueToFilter = (value) => {
  if (!value || value === 'all') return { project: 'all' };

  const [language, project] = value.split('.');
  if (project) return { language, project };

  return { language: null, project: value };
};

const wikiFilterToValue = (wikiFilter) => {
  if (wikiFilter.language) {
    return `${wikiFilter.language}.${wikiFilter.project}`;
  }

  return wikiFilter.project;
};

const matchesWikiFilter = (row, wikiFilter) => {
  if (!wikiFilter || wikiFilter.project === 'all') return true;

  return row.language === wikiFilter.language && row.project === wikiFilter.project;
};

const getWikiOptions = (rows) => {
  const seen = new Set();
  const options = [];

  rows.forEach((row) => {
    if (!row.project) return;

    const value = row.language ? `${row.language}.${row.project}` : row.project;
    if (seen.has(value)) return;

    seen.add(value);
    options.push({ value, label: value });
  });

  return options.sort((a, b) => a.label.localeCompare(b.label));
};

const updateSearchParams = (filter, value) => {
  if (typeof window === 'undefined') return;

  const params = new URLSearchParams(window.location.search);
  if (defaultParams[filter] === value) {
    params.delete(filter);
  } else {
    params.set(filter, value);
  }

  const search = params.toString();
  const nextUrl = search ? `${window.location.pathname}?${search}` : window.location.pathname;
  window.history.replaceState(null, null, nextUrl);
};

const ContributionStats = ({ params, stats, statsGraphsData }) => {
  const [isStudent] = useState(JSON.parse(document.querySelector('#react_root')?.dataset.isstudent));
  const [isInstructor] = useState(JSON.parse(document.querySelector('#react_root')?.dataset.isinstructor));
  const [wikiFilter, setWikiFilter] = useState(() => wikiValueToFilter(getSearchParam('wiki', defaultParams.wiki)));
  let contriStats;
  const graphWidth = 800;
  const graphHeight = 250;
  const articlesByLanguage = stats.articles_by_language || [];
  const wikiOptions = useMemo(() => getWikiOptions(articlesByLanguage), [articlesByLanguage]);
  const filteredArticlesByLanguage = useMemo(
    () => articlesByLanguage.filter(row => matchesWikiFilter(row, wikiFilter)),
    [articlesByLanguage, wikiFilter]
  );
  const showWikiFilter = wikiOptions.length > 0;

  const wikiFilterKeys = useMemo(() => {
    const keys = {
      all: {
        label: I18n.t('articles.filter.wiki_all')
      }
    };

    wikiOptions.forEach((option) => {
      keys[option.value] = {
        label: option.label
      };
    });

    const selectedKey = wikiFilterToValue(wikiFilter);
    if (keys[selectedKey]) {
      keys[selectedKey].order = 'asc';
    }

    return keys;
  }, [wikiOptions, wikiFilter]);

  const onWikiSelect = (value) => {
    updateSearchParams('wiki', value);
    setWikiFilter(wikiValueToFilter(value));
  };

  if (isInstructor.instructor) {
    contriStats = (
      <InstructorStats
        username={params.username}
        stats={stats}
        isStudent={isStudent.student}
        statsGraphsData={statsGraphsData}
        graphWidth={graphWidth}
        graphHeight={graphHeight}
        maxProject={stats.max_project}
      />
    );
  } else if (isStudent.student) {
    contriStats = (
      <StudentStats
        username={params.username}
        stats={stats.as_student}
        statsGraphsData={statsGraphsData}
        graphWidth={graphWidth}
        graphHeight={graphHeight}
        maxProject={stats.max_project}
      />
    );
  }

  useEffect(() => {
    if (wikiFilter.project !== 'all' && !wikiOptions.some(option => option.value === wikiFilterToValue(wikiFilter))) {
      setWikiFilter({ project: 'all' });
      updateSearchParams('wiki', 'all');
    }
  }, [wikiFilter, wikiOptions]);

  return (
    <div id="statistics">
      <div className="user-articles__header">
        <h2>{I18n.t('users.contribution_statistics')}</h2>
        <ProfileDownloadButtons
          username={params.username}
          section="statistics"
          data={{ username: params.username, ...stats, articles_by_language: filteredArticlesByLanguage }}
        />
      </div>
      {showWikiFilter && (
        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '12px', marginBottom: '24px' }}>
          <div
            className="user-articles__filters"
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              gap: '12px',
              flexWrap: 'wrap',
            }}
          >
            <b>{I18n.t('articles.filter_text')}</b>
            <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
              <DropdownSortSelect keys={wikiFilterKeys} sortSelect={onWikiSelect} />
            </div>
          </div>
        </div>
      )}
      {contriStats}

      {/* Stats by Language/Project */}
      {filteredArticlesByLanguage.length > 0 && (
        <div className="user-articles__header" style={{ marginTop: '30px' }}>
          <h3 className="user_stats__title">{I18n.t('users.contributions_by_language')}</h3>
        </div>
      )}
      {filteredArticlesByLanguage.length > 0 && (
        <div className="user-details-table-wrap">
          <table className="table user-details-table">
            <thead>
              <tr>
                <th>{I18n.t('articles.language') || 'Language'}</th>
                <th>{I18n.t('articles.project') || 'Project'}</th>
                <th className="user-details-table__value">{I18n.t('metrics.word_count')}</th>
                <th className="user-details-table__value">{I18n.t('metrics.references_count')}</th>
                <th className="user-details-table__value">{I18n.t('metrics.article_count') || 'Articles'}</th>
              </tr>
            </thead>
            <tbody>
              {filteredArticlesByLanguage.map(lang => (
                <tr key={`${lang.language}-${lang.project}`}>
                  <td>{lang.language}</td>
                  <td>{lang.project}</td>
                  <td className="user-details-table__value">{lang.word_count}</td>
                  <td className="user-details-table__value">{lang.references_count}</td>
                  <td className="user-details-table__value">{lang.article_count}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {articlesByLanguage.length > 0 && filteredArticlesByLanguage.length === 0 && (
        <div className="user-articles__empty-state" style={{ marginTop: '24px' }}>
          <p>No articles match the selected filter.</p>
        </div>
      )}
    </div>
  );
};

ContributionStats.propTypes = {
  params: PropTypes.object,
  stats: PropTypes.object.isRequired
};

export default ContributionStats;