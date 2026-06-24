import React, { useCallback, useEffect, useRef, useState } from 'react';
import request from '../../utils/request';

// NOTE: the visible strings below are functional placeholders — wording should
// be reviewed/replaced by the operator (see project text conventions).

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

  if (!status) return <div className="container"><p>Loading…</p></div>;

  const { job, last_summary: last } = status;
  const pct = job?.pct_complete || 0;

  return (
    <div className="container">
      <h1 style={{ marginTop: '40px' }}>Claim verification</h1>
      <hr />

      <section className="stat-display">
        <p>Pool size: <strong>{status.pool_size}</strong> claims</p>
        {status.last_run_at && last && (
          <p>
            Last run {new Date(status.last_run_at).toLocaleString()}: +{last.harvested} claims
            {' '}from {last.processed} alerts ({last.skipped} skipped
            {last.full_rescan ? ', full re-scan' : ''})
          </p>
        )}
      </section>

      <section style={{ margin: '1em 0' }}>
        <button className="button dark" disabled={active || busy} onClick={() => startHarvest(false)}>
          Harvest claim pool
        </button>
        {' '}
        <button className="button" disabled={active || busy} onClick={() => startHarvest(true)}>
          Full re-scan
        </button>
      </section>

      {job && (
        <section aria-live="polite">
          <p>
            Status: <strong>{job.status}</strong>
            {job.total ? ` — ${job.at || 0} / ${job.total} alerts (${pct}%)` : ''}
          </p>
          <div style={{ background: '#eee', borderRadius: 4, height: 16, maxWidth: 480, overflow: 'hidden' }}>
            <div style={{ background: '#676eb4', height: '100%', transition: 'width .3s', width: `${pct}%` }} />
          </div>
          <p>{job.harvested || 0} harvested · {job.processed || 0} processed · {job.skipped || 0} skipped · {job.errors || 0} errors</p>
          {job.message && <p><small>{job.message}</small></p>}
        </section>
      )}
    </div>
  );
};

export default ClaimVerificationAdmin;
