import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Loading from '../common/loading.jsx';
import CourseQualityProgressGraph from './course_quality_progress_graph';
import { ORESSupportedWiki } from '../../utils/article_finder_language_mappings';
import request from '../../utils/request';

const CourseOresPlot = ({ course }) => {
  const [show, setShow] = useState(false);
  const [refreshedData, setRefreshedData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refresh, setRefresh] = useState(false);
  const [filePath, setFilePath] = useState(null);

  const fetchFile = () => {
    request(`/courses/${course.slug}/refresh_ores_data.json`)
      .then(resp => resp.json())
      .then((data) => {
        setRefreshedData(data.ores_plot);
        setLoading(false);
      });
  };

  const fetchFilePath = () => {
    request(`/courses/${course.slug}/ores_plot.json`)
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

  const refreshHandler = () => {
    setRefreshedData(null);
    fetchFile();
    setShow(false);
    setRefresh(true);
  };

  const hide = () => {
    return setShow(false);
  };

  const isSupportedWiki = () => {
    const wiki = course.home_wiki;
    if (!wiki) { return false; }
    return ORESSupportedWiki.languages.includes(wiki.language) && wiki.project === 'wikipedia';
  };

  const shouldShowButton = () => {
    // Do not show it if there are zero articles edited, or it's not an en-wiki course.
    return isSupportedWiki() && course.edited_count !== '0';
  };

  const displayGraph = (data) => {
    return (
      <div className="ores-plot">
        <CourseQualityProgressGraph graphid={'vega-graph-ores-plot'} graphWidth={1000} graphHeight={200} articleData={data} />
        <p>
          This graph visualizes, in aggregate, how much articles developed from
          before students first edited them until their most recent edits. The <em>Structural Completeness </em>
          rating is based on a machine learning project (<a href="https://www.mediawiki.org/wiki/ORES/FAQ" target="_blank">ORES</a>)
          that estimates an article&apos;s quality rating based on the amount of
          prose, the number of wikilinks, images and section headers, and other features. (<a href="#" onClick={refreshHandler}>Refresh Cached Data</a>)
        </p>
      </div>
    );
  };

  const loadgraph = () => {
    if (loading) {
      return <div onClick={hide}><Loading /></div>;
    }
    return <div>No Structural Completeness data available</div>;
  };

  if (!shouldShowButton()) {
    return <div />;
  }

  if (refresh) {
    if (refreshedData) {
      return (
        displayGraph(refreshedData)
      );
    }
    loadgraph();
  }

  if (show) {
    if (filePath) {
      return (
        displayGraph(filePath)
      );
    }
    loadgraph();
  }
  return (<button className="button small" onClick={showHandler}>Change in Structural Completeness</button>);
};

export default CourseOresPlot;

CourseOresPlot.propTypes = {
  course: PropTypes.object
};
