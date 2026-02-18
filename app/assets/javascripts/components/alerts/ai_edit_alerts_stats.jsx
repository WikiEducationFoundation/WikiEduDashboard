import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import Loading from '../common/loading';
import AiAlertsList from './ai_alerts_list.jsx';
import request from '../../utils/request';
import AlertsTrendsGraph from './graphs/alerts_trends_graph.jsx';
import CoursesWithAiAlertsList from './courses_with_ai_alerts_list.jsx';
import OverviewStat from '../common/OverviewStats/overview_stat';

const AiEditAlertsStats = () => {
  const [stats, setStats] = useState(null);
  const { campaign_slug } = useParams();

  useEffect(() => {
      const fetchAlertsStats = async () => {
        const response = await request(
          `ai_edit_alerts_stats.json?campaign_slug=${campaign_slug}`
        );
        const data = await response.json();
        setStats(data);
      };
      fetchAlertsStats();
    }, [campaign_slug]);

  if (!stats) {
    return <Loading/>;
  }

  return (
    <div className="container">
      <div className="alerts-stats">
        <h1>{I18n.t('alerts.ai_stats.title', { campaign_name: stats.campaign_name })}</h1>

        <div className="stat-display">
          <OverviewStat
            id="total-alerts"
            className={'stat-display__value'}
            stat={stats.total_alerts}
            statMsg={I18n.t('alerts.ai_stats.total_alerts')}
            renderZero={true}
          />
          <OverviewStat
            id="total-followups"
            className={'stat-display__value'}
            stat={stats.total_followups}
            statMsg={I18n.t('alerts.ai_stats.with_followup')}
            renderZero={true}
          />
          <OverviewStat
            id="mutiple-alerts-students"
            className={'stat-display__value'}
            stat={stats.students_with_multiple_alerts}
            statMsg={I18n.t('alerts.ai_stats.multiple_alerts_students')}
            renderZero={true}
          />
          <OverviewStat
            id="multiple-alerts-pages"
            className={'stat-display__value'}
            stat={stats.pages_with_multiple_alerts}
            statMsg={I18n.t('alerts.ai_stats.multiple_alerts_pages')}
            renderZero={true}
          />
        </div>

        <h3 style={{ marginTop: '40px' }}>{I18n.t('alerts.ai_stats.sections.alerts_trend_over_time')}</h3>
        <AlertsTrendsGraph
          statsData={stats.historical_alerts}
          countByPage={stats.by_page_type}
          total={stats.total_alerts}
        />

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
        <CoursesWithAiAlertsList stats={{ total: stats.courses_with_ai_edit_alerts, last_week: stats.courses_with_ai_edit_alerts_last_week }}/>

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
