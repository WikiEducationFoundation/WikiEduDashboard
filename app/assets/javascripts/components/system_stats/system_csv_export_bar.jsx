import React, { useState, useRef, useEffect } from 'react';

const SystemCsvExportBar = ({ campaigns = [], wikis = [] }) => {
  const [campaignSlug, setCampaignSlug] = useState('');
  const [wikiDomain, setWikiDomain] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [exporting, setExporting] = useState(false);
  const [notice, setNotice] = useState(null);

  const timerRef = useRef(null);

  useEffect(() => {
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, []);

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

    const queryString = params.toString();
    const exportUrl = `/system_csv${queryString ? `?${queryString}` : ''}`;

    let attempts = 0;
    const maxAttempts = 12;

    const stopExport = () => {
      if (timerRef.current) clearTimeout(timerRef.current);
      setExporting(false);
      setNotice(null);
    };

    const poll = () => {
      attempts += 1;
      fetch(exportUrl)
        .then(resp => {
          if (!resp.ok) {
            if (timerRef.current) clearTimeout(timerRef.current);
            setExporting(false);
            setNotice(I18n.t('system_stats.filters.fetch_error'));
            return;
          }

          const contentType = resp.headers.get('content-type') || '';
          const isCsv = resp.url.endsWith('.csv') || contentType.includes('csv');

          if (isCsv) {
            stopExport();
            window.location.href = exportUrl;
            return;
          }

          return resp.text().then(text => {
            if (text.includes('generated')) {
              if (attempts < maxAttempts) {
                setNotice(I18n.t('system_stats.filters.generation_queued'));
                timerRef.current = setTimeout(poll, 2500);
              } else {
                setExporting(false);
                setNotice(I18n.t('system_stats.filters.fetch_error'));
              }
            } else {
              stopExport();
              window.location.href = exportUrl;
            }
          });
        })
        .catch(err => {
          console.error(err);
          if (timerRef.current) clearTimeout(timerRef.current);
          setExporting(false);
          setNotice(I18n.t('system_stats.filters.fetch_error'));
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
