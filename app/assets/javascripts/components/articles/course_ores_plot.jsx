import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Loading from '../common/loading.jsx';
import CourseQualityProgressGraph from './course_quality_progress_graph';
import { ORESSupportedWiki } from '../../utils/article_finder_language_mappings';
import request from '../../utils/request';
import { onEnterOrSpace } from '../../utils/keyboard_handlers';

const CourseOresPlot = ({ course }) => {
  const [show, setShow] = useState(false);
  const [refreshedData, setRefreshedData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refresh, setRefresh] = useState(false);
  const [filePath, setFilePath] = useState(null);

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

  const displayGraph = (data) => {
    return (
      <div className="ores-plot">
        <CourseQualityProgressGraph graphid={'vega-graph-ores-plot'} graphWidth={1000} graphHeight={200} articleData={data} />
        {/* Event delegation onto the dangerouslySetInnerHTML-rendered
            <a class="refresh-link">. Keyboard activation comes from the
            anchor itself (Enter on a focused anchor triggers click), so the
            delegation also fires for keyboard users. */}
        {/* eslint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-noninteractive-element-interactions */}
        <p
          dangerouslySetInnerHTML={{
          __html: I18n.t('courses.ores_plot_description', {
            ores_link: '<a href="https://www.mediawiki.org/wiki/ORES/FAQ" target="_blank">ORES</a>',
            refresh_link: `<a href="#" class="refresh-link">${I18n.t('courses.ores_plot_refresh_data')}</a>`
          })
        }}
          onClick={(e) => {
            if (e.target.classList.contains('refresh-link')) {
              e.preventDefault();
              refreshHandler();
            }
          }}
        />
      </div>
    );
  };

  const loadgraph = () => {
    if (loading) {
      return (
        <div
          role="button"
          tabIndex={0}
          onClick={hide}
          onKeyDown={onEnterOrSpace(hide)}
        >
          <Loading />
        </div>
      );
    }
    return <div>{I18n.t('courses.ores_plot_no_data')}</div>;
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
  return (<button className="button small" onClick={showHandler}>{I18n.t('courses.ores_plot_show_button')}</button>);
};

export default CourseOresPlot;

CourseOresPlot.propTypes = {
  course: PropTypes.object
};
