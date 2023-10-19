import React, { useEffect, useRef, useState } from 'react';
import Wp10Graph from './wp10_graph.jsx';
import EditSizeGraph from './edit_size_graph.jsx';
import Loading from '../common/loading.jsx';
import request from '../../utils/request.js';

const ArticleGraphs = ({ article }) => {
  const { id: article_id } = article;

  const [showGraph, setShowGraph] = useState(false);
  const [selectedRadio, setSelectedRadio] = useState('wp10_score');
  const [articleData, setArticleData] = useState(null);

  const elementRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      const element = elementRef.current;
      if (element && !element.contains(event.target)) {
        handleHideGraph();
      }
    };

    const handlePressEscapeKey = (event) => {
      if (event.key === 'Escape') {
        handleHideGraph();
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    document.addEventListener('keydown', handlePressEscapeKey);

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('keydown', handlePressEscapeKey);
    };
  }, []);

  function getData() {
    if (articleData) {
      return;
    }
    const articledataUrl = `/articles/article_data.json?article_id=${article_id}`;
    request(articledataUrl)
      .then(resp => resp.json())
      .then((data) => {
        setArticleData(data);
      });
  }

  function handleShowGraph() {
    getData();
    setShowGraph(true);
  }

  function handleHideGraph() {
    setArticleData(null);
    setShowGraph(false);
  }

  function handleRadioChange(event) {
    setSelectedRadio(event.currentTarget.value);
  }

   const graphId = `vega-graph-${article_id}`;

  const dataIncludesWp10 = articleData?.[0]?.wp10;

  const graph = () => {
    if (!articleData) {
      return <Loading />;
    }

    if (dataIncludesWp10 && selectedRadio === 'wp10_score') {
      return (
        <Wp10Graph
          graphid={graphId}
          graphWidth={500}
          graphHeight={300}
          articleData={articleData}
        />
      );
    }

    return (
      <EditSizeGraph
        graphid={graphId}
        graphWidth={500}
        graphHeight={300}
        articleData={articleData}
      />
    );
  };

  const radioInput = () => {
    if (!dataIncludesWp10 || !articleData) {
      return null;
    }

    return (
      <div>
        <div className="input-row">
          <input
            type="radio"
            name="wp10_score"
            id="wp10_score"
            value="wp10_score"
            checked={selectedRadio === 'wp10_score'}
            onChange={handleRadioChange}
          />
          <label htmlFor="wp10_score">{I18n.t('articles.wp10')}</label>
        </div>
        <div className="input-row">
          <input
            type="radio"
            name="edit_size"
            id="edit_size"
            value="edit_size"
            checked={selectedRadio === 'edit_size'}
            onChange={handleRadioChange}
          />
          <label htmlFor="edit_size">{I18n.t('articles.edit_size')}</label>
        </div>
      </div>
    );
  };

  const editSize = () => {
    if (dataIncludesWp10 || !articleData) {
      return null;
    }

    return <p>{I18n.t('articles.edit_size')}</p>;
  };

  const className = `vega-graph ${showGraph ? '' : 'hidden'}`;

  return (
    <a onClick={handleShowGraph} className="inline">
      {I18n.t('articles.article_development')}
      <div className={className} ref={elementRef}>
        <div className="radio-row">
          {radioInput()}
          {editSize()}
        </div>
        {graph()}
      </div>
    </a>
  );
};

export default ArticleGraphs;
