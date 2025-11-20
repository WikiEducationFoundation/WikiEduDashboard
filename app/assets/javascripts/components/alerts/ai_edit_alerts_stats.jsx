import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import Loading from '../common/loading';
import AiAlertsList from './ai_alerts_list.jsx';
import request from '../../utils/request';
import AlertsTrendsGraph from './graphs/alerts_trends_graph.jsx';
import CoursesWithAiAlertsList from './courses_with_ai_alerts_list.jsx';

const AiEditAlertsStats = () => {
  const [stats, setStats] = useState(null);
  const { campaign_id } = useParams();

  useEffect(() => {
      const fetchAlertsStats = async () => {
        const response = await request(
          `ai_edit_alerts_stats.json?campaign_id=${campaign_id}`
        );
        const data = await response.json();
        setStats(data);
      };
      fetchAlertsStats();
    }, [campaign_id]);

  if (!stats) {
    return <Loading/>;
  }

  return (
    <div className="container">
      <div className="alerts-stats">
        <h1>{I18n.t('alerts.ai_stats.title')}</h1>

        <h3 style={{ marginTop: '40px' }}>{I18n.t('alerts.ai_stats.sections.alerts_trend_over_time')}</h3>
        <AlertsTrendsGraph
          statsData={stats.historical_alerts}
        />
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

        <h3 id="contents" style={{ marginTop: '40px' }}>{I18n.t('alerts.ai_stats.sections.contents')}</h3>
        <table className="table table--striped" style={{ marginTop: '20px' }}>
          <thead>
            <tr>
              <th>{I18n.t('alerts.ai_stats.sections.name')}</th>
              <th>{I18n.t('alerts.ai_stats.sections.description')}</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>
                <a href="#courses_with_ai_alerts">
                  {I18n.t('alerts.ai_stats.sections.courses_with_ai_alerts')}
                </a>
              </td>
              <td>{I18n.t('alerts.ai_stats.sections.descriptions.courses_with_ai_alerts')}</td>
            </tr>
            <tr>
              <td>
                <a href="#recent_followup">
                  {I18n.t('alerts.ai_stats.sections.recent_followup')}
                </a>
              </td>
              <td>{I18n.t('alerts.ai_stats.sections.descriptions.recent_followup')}</td>
            </tr>
            <tr>
              <td>
                <a href="#multiple_alerts">
                  {I18n.t('alerts.ai_stats.sections.multiple_alerts_students')}
                </a>
              </td>
              <td>{I18n.t('alerts.ai_stats.sections.descriptions.multiple_alerts_students')}</td>
            </tr>
            <tr>
              <td>
                <a href="#in_mainspace">
                  {I18n.t('alerts.ai_stats.sections.in_mainspace')}
                </a>
              </td>
              <td>{I18n.t('alerts.ai_stats.sections.descriptions.in_mainspace')}</td>
            </tr>
          </tbody>
        </table>

        <h3 id="courses_with_ai_alerts" style={{ marginTop: '40px' }}>{I18n.t('alerts.ai_stats.sections.courses_with_ai_alerts')}</h3>
        <a href="#contents">{I18n.t('alerts.ai_stats.sections.go_back')}</a>
        <CoursesWithAiAlertsList stats={stats.courses_with_ai_edit_alerts}/>

        <h3 id="recent_followup" style={{ marginTop: '40px' }}>{I18n.t('alerts.ai_stats.sections.recent_followup')}</h3>
        <a href="#contents">{I18n.t('alerts.ai_stats.sections.go_back')}</a>
        <AiAlertsList
          alerts={stats.recent_alerts_followup}
          noAlertsLabel={I18n.t('alerts.no_data')}
        />
        <h3 id="multiple_alerts" style={{ marginTop: '40px' }}>{I18n.t('alerts.ai_stats.sections.multiple_alerts_students')}</h3>
        <a href="#contents">{I18n.t('alerts.ai_stats.sections.go_back')}</a>
        <AiAlertsList
          alerts={stats.recent_alerts_for_students_with_multiple_alerts}
          noAlertsLabel={I18n.t('alerts.no_data')}
        />
        <h3 id="in_mainspace" style={{ marginTop: '40px' }}>{I18n.t('alerts.ai_stats.sections.in_mainspace')}</h3>
        <a href="#contents">{I18n.t('alerts.ai_stats.sections.go_back')}</a>
        <AiAlertsList
          alerts={stats.recent_alerts_for_mainspace}
          noAlertsLabel={I18n.t('alerts.no_data')}
        />
      </div>
    </div>
  );
};

export default AiEditAlertsStats;
