import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import Loading from '../common/loading';
import AiAlertsList from './ai_alerts_list.jsx';

import { sortAlerts, fetchAlertsStats } from '../../actions/alert_actions';

const AiEditAlertsStats = () => {
  const dispatch = useDispatch();

  useEffect(() => {
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

        <h3>General Stats for {stats.current_term} Campaign</h3>
        <table style={{ marginBottom: '40px' }} className="table table--striped">
          <thead>
            <tr>
              <th>Total AI Edit Alerts</th>
              <th>With followup</th>
              <th>Students with multiple alerts</th>
              <th>Pages with multiple alerts</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>{stats.total_alerts}</td>
              <td>{stats.total_followups}</td>
              <td>{stats.students_with_multiple_alerts}</td>
              <td>{stats.pages_with_multiple_alerts}</td>
            </tr>
          </tbody>
        </table>

        <h3>By Page Type</h3>
        <table style={{ marginBottom: '40px' }} className="table table--striped">
          <thead>
            <tr>
              <th>Page</th>
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
        <h3 style={{ marginTop: '40px' }}>Alerts with recent followup</h3>
        <AiAlertsList
          alerts={stats.recent_alerts_followup}
          sortBy={key => dispatch(sortAlerts(key))}
          noAlertsLabel={I18n.t('alerts.no_alerts')}
          adminAlert={false}
        />
        <h3 style={{ marginTop: '40px' }}>Recent alerts for students with multiple alerts</h3>
        <AiAlertsList
          alerts={stats.recent_alerts_for_students_with_multiple_alerts}
          sortBy={key => dispatch(sortAlerts(key))}
          noAlertsLabel={I18n.t('alerts.no_alerts')}
          adminAlert={false}
        />
        <h3 style={{ marginTop: '40px' }}>Recent alerts in mainspace</h3>
        <AiAlertsList
          alerts={stats.recent_alerts_for_mainspace}
          sortBy={key => dispatch(sortAlerts(key))}
          noAlertsLabel={I18n.t('alerts.no_alerts')}
          adminAlert={false}
        />
      </div>
    </div>
  );
};

export default AiEditAlertsStats;
