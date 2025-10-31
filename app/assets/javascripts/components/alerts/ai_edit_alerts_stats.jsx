import React, { useEffect, useState } from 'react';
import Loading from '../common/loading';
import AiAlertsList from './ai_alerts_list.jsx';
import request from '../../utils/request';
import AlertsTrendsGraph from './graphs/alerts_trends_graph.jsx';

const AiEditAlertsStats = () => {
  const [stats, setStats] = useState(null);

  useEffect(() => {
      const fetchAlertsStats = async () => {
        const response = await request(
          'ai_edit_alerts_stats.json'
        );
        const data = await response.json();
        setStats(data);
      };
      fetchAlertsStats();
    }, []);

  if (!stats) {
    return <Loading/>;
  }

  return (
    <div className="container">
      <div className="alerts-stats">
        <h1>{I18n.t('alerts.ai_stats.title')}</h1>

        <h3>{I18n.t('alerts.ai_stats.general_stats', { campaign_name: stats.current_term })}</h3>
        <table style={{ marginBottom: '40px' }} className="table table--striped">
          <thead>
            <tr>
              <th>{I18n.t('alerts.ai_stats.total_alerts')}</th>
              <th>{I18n.t('alerts.ai_stats.with_followup')}</th>
              <th>{I18n.t('alerts.ai_stats.multiple_alerts_students')}</th>
              <th>{I18n.t('alerts.ai_stats.multiple_alerts_pages')}</th>
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

        <h3>{I18n.t('alerts.ai_stats.by_page_type')}</h3>
        <table style={{ marginBottom: '40px' }} className="table table--striped">
          <thead>
            <tr>
              <th>{I18n.t('alerts.ai_stats.page_type')}</th>
              <th>{I18n.t('alerts.ai_stats.count')}</th>
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
        <h3 style={{ marginTop: '40px' }}>{I18n.t('alerts.ai_stats.sections.recent_followup')}</h3>
        <AiAlertsList
          alerts={stats.recent_alerts_followup}
          noAlertsLabel={I18n.t('alerts.no_alerts')}
          adminAlert={false}
        />
        <h3 style={{ marginTop: '40px' }}>{I18n.t('alerts.ai_stats.sections.multiple_alerts_students')}</h3>
        <AiAlertsList
          alerts={stats.recent_alerts_for_students_with_multiple_alerts}
          noAlertsLabel={I18n.t('alerts.no_alerts')}
          adminAlert={false}
        />
        <h3 style={{ marginTop: '40px' }}>{I18n.t('alerts.ai_stats.sections.in_mainspace')}</h3>
        <AiAlertsList
          alerts={stats.recent_alerts_for_mainspace}
          noAlertsLabel={I18n.t('alerts.no_alerts')}
          adminAlert={false}
        />
        <h3 style={{ marginTop: '40px' }}>{I18n.t('alerts.ai_stats.sections.alerts_trend_over_time')}</h3>
        <AlertsTrendsGraph
          statsData={stats.historical_alerts}
        />
      </div>
    </div>
  );
};

export default AiEditAlertsStats;
