import React, { useEffect, useState } from 'react';
import Modal from '../common/modal';
import Loading from '../common/loading';
import request from '../../utils/request';
import { getArticleUrl } from '../../utils/wiki_utils';

const ArticleTitlesModal = ({ setShowModal, category, course, lastUpdateMessage }) => {
  const [articlesTitles, setArticlesTitles] = useState(null);
  const [filteredArticles, setFilteredArticles] = useState(null);
  const [wiki, setWiki] = useState(null);
  useEffect(() => {
    const getCategoryInfo = async () => {
      const response = await request(
        `/categories/${category.id}?course_id=${course.id}`
      );
      const data = await response.json();
      const uniqueArticles = [...new Set(data.category.article_titles)];
      setArticlesTitles(uniqueArticles);
      setFilteredArticles(uniqueArticles);
      setWiki(data.category.wiki);
    };
    getCategoryInfo();
  }, []);

  const filterOnChangeHandler = (e) => {
    const filtered = articlesTitles.filter(title => title.replaceAll('_', ' ').toLowerCase().includes(e.target.value.toLowerCase()));
    setFilteredArticles(filtered);
  };

  return (
    <Modal key={'modal'}>
      <div className="container">
        <div className="wizard__panel active">
          {!articlesTitles ? (
            <div
              style={{
                display: 'flex',
                flexDirection: 'column',
                gap: '0.5em',
              }}
            >
              <Loading text="Loading articles" />
              <button
                className="button dark"
                onClick={() => setShowModal(false)}
              >
                {I18n.t('metrics.close_modal')}
              </button>
            </div>
          ) : (
            <div
              style={{
                display: 'flex',
                flexDirection: 'column',
                gap: '0.5em',
              }}
            >
              <div style={{
                display: 'flex',
                flexDirection: 'column',
              }}
              >
                <h3 style={{
                  marginBottom: '0.5em',
                }}
                >
                  {I18n.t('articles.tracked_articles')} for
                  <span style={{
                    textTransform: 'capitalize',
                  }}
                  >
                    {` ${category.source}: ${category.name.replaceAll('_', ' ')}`}
                  </span>
                </h3>
                <small>
                  {lastUpdateMessage}
                </small>
              </div>

              <input
                type="text"
                onChange={filterOnChangeHandler}
                placeholder="Filter articles by title"
              />
              {filteredArticles.length ? (
                <ul
                  style={{
                  maxHeight: '300px',
                  overflowY: 'scroll',
                }}
                >
                  {filteredArticles.map(articleTitle => (
                    <li key={articleTitle}>
                      <a
                        href={getArticleUrl(wiki, articleTitle)}
                        style={{
                        textTransform: 'capitalize',
                        textDecoration: 'none',
                      }}
                        target="_blank"
                      >
                        {articleTitle.replaceAll('_', ' ')}
                      </a>
                    </li>
                ))}
                </ul>
              ) : (
                <p>{I18n.t('articles.no_tracked_articles')}</p>
              )}
              <button
                className="button dark"
                onClick={() => setShowModal(false)}
              >
                {I18n.t('metrics.close_modal')}
              </button>
            </div>
          )}
        </div>
      </div>
    </Modal>
  );
};

export default ArticleTitlesModal;
