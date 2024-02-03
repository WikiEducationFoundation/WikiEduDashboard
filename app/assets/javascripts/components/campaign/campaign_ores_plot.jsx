import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import Loading from '../common/loading.jsx';
import CourseQualityProgressGraph from '../articles/course_quality_progress_graph';
import request from '../../utils/request';
import withRouter from '../util/withRouter';

const CampaignOresPlot = (props) => {
  const [show, setShow] = useState(false);
  const [loading, setLoading] = useState(true);
  const [filePath, setFilePath] = useState(null);

  useEffect(() => {
     // This clears Rails parts of the previous pages, when changing Campagn tabs
     if (document.getElementById('users')) {
      document.getElementById('users').innerHTML = '';
    }
    if (document.getElementById('campaign-articles')) {
      document.getElementById('campaign-articles').innerHTML = '';
    }
    if (document.getElementById('courses')) {
      document.getElementById('courses').innerHTML = '';
    }
    if (document.getElementById('overview-campaign-details')) {
      document.getElementById('overview-campaign-details').innerHTML = '';
    }
  }, []);

  const fetchFilePath = () => {
    request(`/campaigns/${props.router.params.campaign_slug}/ores_data.json`)
      .then(resp => resp.json())
      .then((data) => {
        setFilePath(data.ores_plot);
        setLoading(false);
      });
  };

  const showHandler = () => {
    if (!filePath) {
      fetchFilePath();
    }
    return setShow(true);
  };

  const hideHandler = () => {
    return setShow(false);
  };

  if (show) {
    if (filePath) {
      return (
        <div id="ores" className="ores-plot">
          <CourseQualityProgressGraph graphid={'vega-graph-ores-plot'} graphWidth={1000} graphHeight={400} articleData={filePath} />
          <p>
            This graph visualizes, in aggregate, how much articles developed from
            before campaign participants first edited them until the most recent campagin edits. The <em>Structural Completeness </em>
            rating is based on a machine learning project (<a href="https://www.mediawiki.org/wiki/ORES/FAQ" target="_blank">ORES</a>)
            that estimates an article&apos;s quality rating based on the amount of
            prose, the number of wikilinks, images and section headers, and other features.
          </p>
        </div>
      );
    }
    if (loading) {
      return <div onClick={hideHandler}><Loading /></div>;
    }
    return <div>No Structural Completeness data available</div>;
  }
  return (
    <button className="button small" onClick={showHandler}>Change in Structural Completeness</button>
  );
};

CampaignOresPlot.propTypes = {
  match: PropTypes.object
};

CampaignOresPlot.displayName = 'CampaignOresPlot';

export default withRouter(CampaignOresPlot);
