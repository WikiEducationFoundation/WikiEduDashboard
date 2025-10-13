import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import Loading from '../common/loading';

import { fetchAlertsStats } from '../../actions/alert_actions';

const AiEditAlertsStats = () => {
  const dispatch = useDispatch();

  useEffect(() => {
    // This adds alerts stats to the state
    dispatch(fetchAlertsStats());
  }, [dispatch]);

  const alerts = useSelector(state => state.alerts);
  const stats = alerts.alerts_stats;

  if (!stats) {
    return <Loading/>;
  }

  return (
    <div className="container">
      <div className="alerts-stats">
        <h1>AI Edit Alerts Stats</h1>

        <h2>
          AI edit alerts in the last 30 days: <strong>{stats.total_alerts}</strong>.
          See a list of <a href={'/alerts_list/'}> individual alerts </a>.
        </h2>

        <h3>By Page Type</h3>
        <table style={{ marginBottom: '40px' }} className="table table--striped">
          <thead>
            <tr>
              <th>Page Type</th>
              <th>Count</th>
              <th>%</th>
            </tr>
          </thead>
          <tbody>
            {Object.entries(stats.by_page_type).map(([pageType, count]) => (
              <tr key={pageType}>
                <td>{pageType}</td>
                <td>{count}</td>
                <td>{Math.round(count * 100 / stats.total_alerts)}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <h2>AI edit alerts in the last 30 days with at least one followup: <strong>{stats.total_followups}</strong></h2>

        <h3>False Positives</h3>
        <table className="table table--striped">
          <thead>
            <tr>
              <th>How Used It</th>
              <th>Count</th>
              <th>%</th>
            </tr>
          </thead>
          <tbody>
            {Object.entries(stats.false_positives).map(([pageType, count]) => (
              <tr key={pageType}>
                <td>{pageType}</td>
                <td>{count}</td>
                <td>{Math.round(count * 100 / stats.total_followups)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default AiEditAlertsStats;
