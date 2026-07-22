import React, { useState, useRef, useEffect } from 'react';

const COURSE_TYPES = [
  { value: 'ClassroomProgramCourse', label: 'Classroom Program' },
  { value: 'Editathon', label: 'Editathon' },
  { value: 'BasicCourse', label: 'Basic Course' },
  { value: 'FellowsCohort', label: 'Fellows Cohort' },
  { value: 'ArticleScopedProgram', label: 'Article Scoped Program' },
  { value: 'VisitingScholarship', label: 'Visiting Scholarship' },
  { value: 'LegacyCourse', label: 'Legacy Course' },
  { value: 'SingleUser', label: 'Single User' },
];

const SystemCsvExportBar = ({ campaigns = [], wikis = [] }) => {
  const [campaignSlug, setCampaignSlug] = useState('');
  const [wikiDomain, setWikiDomain] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [courseType, setCourseType] = useState('');
  const [status, setStatus] = useState('');
  const [exporting, setExporting] = useState(false);
  const [notice, setNotice] = useState(null);

  const timerRef = useRef(null);

  useEffect(() => {
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, []);

  const triggerDownload = (url) => {
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', url.split('/').pop());
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleExport = () => {
    if (exporting) return;

    if (timerRef.current) clearTimeout(timerRef.current);
    setExporting(true);
    setNotice(null);

    const params = new URLSearchParams();
    if (campaignSlug) params.append('campaign_slug', campaignSlug);
    if (wikiDomain) params.append('wiki_domain', wikiDomain);
    if (startDate) params.append('start_date', startDate);
    if (endDate) params.append('end_date', endDate);
    if (courseType) params.append('course_type', courseType);
    if (status) params.append('status', status);

    const queryString = params.toString();
    const exportUrl = `/system_csv${queryString ? `?${queryString}` : ''}`;

    let attempts = 0;
    const maxAttempts = 15; // 15 attempts x 6s = 90s total polling window

    const stopExport = (noticeMsg = null) => {
      if (timerRef.current) clearTimeout(timerRef.current);
      setExporting(false);
      setNotice(noticeMsg);
    };

    const poll = () => {
      attempts += 1;
      fetch(exportUrl, { headers: { Accept: 'application/json' } })
        .then(resp => resp.json().then(data => ({ resp, data })))
        .then(({ resp, data }) => {
          if (resp.status === 422) {
            stopExport(data.error || I18n.t('system_stats.filters.fetch_error'));
            return;
          }

          if (!resp.ok && resp.status !== 202) {
            stopExport(I18n.t('system_stats.filters.fetch_error'));
            return;
          }

          if (data.status === 'ready') {
            stopExport();
            triggerDownload(data.url);
            return;
          }

          // status === 'generating' (202 Accepted)
          if (attempts < maxAttempts) {
            setNotice(I18n.t('system_stats.filters.generation_queued'));
            timerRef.current = setTimeout(poll, 6000);
          } else {
            stopExport(I18n.t('system_stats.filters.fetch_error'));
          }
        })
        .catch(err => {
          console.error(err);
          stopExport(I18n.t('system_stats.filters.fetch_error'));
        });
    };

    poll();
  };

  return (
    <div className="system-stats__filter-card">
      {notice && (
        <div className="notification" role="status">
          <p>{notice}</p>
        </div>
      )}

      <div className="system-stats__filter-row">
        {/* Campaign Filter */}
        <div className="system-stats__filter-group">
          <label htmlFor="system-csv-campaign-select">
            {I18n.t('system_stats.filters.campaign')}
          </label>
          <select
            id="system-csv-campaign-select"
            value={campaignSlug}
            onChange={e => setCampaignSlug(e.target.value)}
          >
            <option value="">{I18n.t('system_stats.filters.all_campaigns')}</option>
            {campaigns.map(c => (
              <option key={c.slug} value={c.slug}>
                {c.title}
              </option>
            ))}
          </select>
        </div>

        {/* Home Wiki Filter */}
        <div className="system-stats__filter-group">
          <label htmlFor="system-csv-wiki-select">
            {I18n.t('system_stats.filters.home_wiki')}
          </label>
          <select
            id="system-csv-wiki-select"
            value={wikiDomain}
            onChange={e => setWikiDomain(e.target.value)}
          >
            <option value="">{I18n.t('system_stats.filters.all_wikis')}</option>
            {wikis.map(domain => (
              <option key={domain} value={domain}>
                {domain}
              </option>
            ))}
          </select>
        </div>

        {/* Start Date */}
        <div className="system-stats__filter-group">
          <label htmlFor="system-csv-start-date">
            {I18n.t('system_stats.filters.start_date')}
          </label>
          <input
            id="system-csv-start-date"
            type="date"
            value={startDate}
            onChange={e => setStartDate(e.target.value)}
          />
        </div>

        {/* End Date */}
        <div className="system-stats__filter-group">
          <label htmlFor="system-csv-end-date">
            {I18n.t('system_stats.filters.end_date')}
          </label>
          <input
            id="system-csv-end-date"
            type="date"
            value={endDate}
            onChange={e => setEndDate(e.target.value)}
          />
        </div>

        {/* Course Type Filter */}
        <div className="system-stats__filter-group">
          <label htmlFor="system-csv-course-type-select">
            {I18n.t('system_stats.filters.course_type')}
          </label>
          <select
            id="system-csv-course-type-select"
            value={courseType}
            onChange={e => setCourseType(e.target.value)}
          >
            <option value="">{I18n.t('system_stats.filters.all_types')}</option>
            {COURSE_TYPES.map(ct => (
              <option key={ct.value} value={ct.value}>
                {ct.label}
              </option>
            ))}
          </select>
        </div>

        {/* Status Filter */}
        <div className="system-stats__filter-group">
          <label htmlFor="system-csv-status-select">
            {I18n.t('system_stats.filters.status')}
          </label>
          <select
            id="system-csv-status-select"
            value={status}
            onChange={e => setStatus(e.target.value)}
          >
            <option value="">{I18n.t('system_stats.filters.all_statuses')}</option>
            <option value="active">{I18n.t('system_stats.filters.active')}</option>
            <option value="archived">{I18n.t('system_stats.filters.archived')}</option>
          </select>
        </div>

        {/* Export CSV Button */}
        <button
          type="button"
          className="system-stats__export-button"
          onClick={handleExport}
          disabled={exporting}
        >
          {exporting
            ? I18n.t('system_stats.filters.generating')
            : I18n.t('system_stats.filters.export_csv')}
        </button>
      </div>
    </div>
  );
};

export default SystemCsvExportBar;
