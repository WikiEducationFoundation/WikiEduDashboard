import React, { useCallback, useEffect, useRef, useState } from 'react';
import request from '../../utils/request';

// Visible strings live in the `claim_verification.admin` locale namespace.

const POLL_MS = 3000;

const ClaimVerificationAdmin = () => {
  const [status, setStatus] = useState(null);
  const [busy, setBusy] = useState(false);
  const pollRef = useRef(null);

  const fetchStatus = useCallback(async () => {
    const response = await request('/claim_verification/status.json');
    const data = await response.json();
    setStatus(data);
    return data;
  }, []);

  useEffect(() => { fetchStatus(); }, [fetchStatus]);

  // Poll only while a harvest is active; stop when it finishes.
  const active = status?.job?.active;
  useEffect(() => {
    if (active && !pollRef.current) {
      pollRef.current = setInterval(fetchStatus, POLL_MS);
    } else if (!active && pollRef.current) {
      clearInterval(pollRef.current);
      pollRef.current = null;
    }
    return () => {
      if (pollRef.current) {
        clearInterval(pollRef.current);
        pollRef.current = null;
      }
    };
  }, [active, fetchStatus]);

  const startHarvest = async (fullRescan) => {
    setBusy(true);
    try {
      const response = await request('/claim_verification/harvest', {
        method: 'POST',
        body: JSON.stringify({ full_rescan: fullRescan })
      });
      const data = await response.json();
      setStatus(data.status);
    } finally {
      setBusy(false);
    }
  };

  if (!status) return <div className="container"><p>{I18n.t('claim_verification.admin.loading')}</p></div>;

  const { job, last_summary: last } = status;
  const pct = job?.pct_complete || 0;

  return (
    <div className="container">
      <h1 style={{ marginTop: '40px' }}>{I18n.t('claim_verification.admin.heading')}</h1>
      <hr />

      <section className="stat-display">
        <p>{I18n.t('claim_verification.admin.pool_size', { count: status.pool_size })}</p>
        {status.last_run_at && last && (
          <p>
            {I18n.t('claim_verification.admin.last_run', {
              time: new Date(status.last_run_at).toLocaleString(),
              harvested: last.harvested,
              processed: last.processed,
              skipped: last.skipped,
              rescan: last.full_rescan ? I18n.t('claim_verification.admin.full_rescan_note') : ''
            })}
          </p>
        )}
      </section>

      <section style={{ margin: '1em 0' }}>
        <button className="button dark" disabled={active || busy} onClick={() => startHarvest(false)}>
          {I18n.t('claim_verification.admin.harvest')}
        </button>
        {' '}
        <button className="button" disabled={active || busy} onClick={() => startHarvest(true)}>
          {I18n.t('claim_verification.admin.full_rescan')}
        </button>
      </section>

      {job && (
        <section aria-live="polite">
          <p>
            {I18n.t('claim_verification.admin.status', { status: job.status })}
            {job.total
              ? I18n.t('claim_verification.admin.progress', { at: job.at || 0, total: job.total, pct })
              : ''}
          </p>
          <div style={{ background: '#eee', borderRadius: 4, height: 16, maxWidth: 480, overflow: 'hidden' }}>
            <div style={{ background: '#676eb4', height: '100%', transition: 'width .3s', width: `${pct}%` }} />
          </div>
          <p>
            {I18n.t('claim_verification.admin.counts', {
              harvested: job.harvested || 0,
              processed: job.processed || 0,
              skipped: job.skipped || 0,
              errors: job.errors || 0
            })}
          </p>
          {job.message && <p><small>{job.message}</small></p>}
        </section>
      )}
    </div>
  );
};

export default ClaimVerificationAdmin;
