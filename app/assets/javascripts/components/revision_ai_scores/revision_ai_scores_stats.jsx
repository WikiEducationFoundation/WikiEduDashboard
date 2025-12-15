import React, { useEffect, useState } from 'react';
import Loading from '../common/loading';
import request from '../../utils/request';
import ScoresTrendsGraph from './graphs/scores_trends_graph.jsx';
import ScoresTrendsInBinsGraph from './graphs/scores_trends_in_bins_graph.jsx';
import LikelihoodDistributionGraph from './graphs/likelihood_distribution_graph.jsx';

const RevisionAiScoresStats = () => {
  const [stats, setStats] = useState(null);

  useEffect(() => {
      const fetchScoresStats = async () => {
        const response = await request(
          'revision_ai_scores_stats.json'
        );
        const data = await response.json();
        setStats(data);
      };
      fetchScoresStats();
    }, []);

  if (!stats) {
    return <Loading/>;
  }

  return (
    <div className="container">
      <div className="alerts-stats">
        <h1>{I18n.t('ai_scores_stats.title')}</h1>

        <h3 style={{ marginTop: '40px' }}>{I18n.t('ai_scores_stats.graphs.daily_checks')}</h3>
        <ScoresTrendsGraph
          id="Namespaces"
          statsData={stats.historical_scores_by_namespace}
        />
        <h3 style={{ marginTop: '40px' }}>{I18n.t('ai_scores_stats.graphs.avg_likelihood')}</h3>
        <ScoresTrendsInBinsGraph
          id="AvgLikelihood"
          statsData={stats.historical_scores_by_avg}
        />
        <h3 style={{ marginTop: '40px' }}>{I18n.t('ai_scores_stats.graphs.max_likelihood')}</h3>
        <ScoresTrendsInBinsGraph
          id="MaxLikelihood"
          statsData={stats.historical_scores_by_max}
        />
        <h3 style={{ marginTop: '40px' }}>{I18n.t('ai_scores_stats.graphs.overall_avg_likelihood')}</h3>
        <LikelihoodDistributionGraph
          id="Avg"
          statsData={stats.avg_likelihoods}
        />
        <h3 style={{ marginTop: '40px' }}>{I18n.t('ai_scores_stats.graphs.overall_max_likelihood')}</h3>
        <LikelihoodDistributionGraph
          id="Max"
          statsData={stats.max_likelihoods}
        />
      </div>
    </div>
  );
};

export default RevisionAiScoresStats;
