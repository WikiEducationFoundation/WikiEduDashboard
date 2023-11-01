import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useParams } from 'react-router-dom';
import { fetchTrainingLibrary } from '../../actions/training_actions';

const TrainingLibrary = () => {
  const { library_id } = useParams();
  const library = useSelector(state => state.training.library);
  const dispatch = useDispatch();
  const breadcrumbs = JSON.parse(document.getElementById('react_root').getAttribute('breadcrumbs'));
  const trainingLibrary = breadcrumbs[0];
  const libraryName = breadcrumbs[1];

  useEffect(() => {
    dispatch(fetchTrainingLibrary(library_id));
  }, [dispatch, library_id]);

  return (
    <>
      <div className="container">
        <ol className="breadcrumbs">
          <li>
            <a href="/training"><span>{trainingLibrary.name}</span></a> &gt; <span>{libraryName.name}</span>
          </li>
        </ol>
      </div>
      <div className="training__section-overview container">
        <section className="training__header">
          <h1>{library.name}</h1>
          <p>{library.introduction}</p>
        </section>

        {library.categories && library.categories.length > 0 ? (
          <ul className="training__categories">
            {library.categories.map((libCategory, index) => (
              <li key={index}>
                <div className="training__category__header">
                  <h1 className="h3">{libCategory.title}</h1>
                  <p>{libCategory.description}</p>
                  {library.wiki_page && (
                  <div className="training__category__source">
                    <a href={`https://meta.wikimedia.org/wiki/${library.wiki_page}`}>
                      {I18n.t('training.view_library_source')}
                    </a>
                  </div>
                  )}
                </div>
                <ul className="training__categories__modules">
                  {libCategory.modules.map((libModule, moduleIndex) => (
                    <li key={moduleIndex}>
                      <a href={`/training/${library.slug}/${libModule.slug}`} className="action-card">
                        <header className="action-card-header">
                          <h3 className="action-card-title">{libModule.name}</h3>
                          <span className="pull-right action-card-title__completion">
                            {libModule.percent_complete}
                          </span>
                          <span className="icon-container">
                            <i className="action-card-icon icon icon-rt_arrow" />
                          </span>
                        </header>
                        <p className="action-card-text">
                          <span>{libModule.description}</span>
                        </p>
                      </a>
                    </li>
                  ))}
                </ul>
              </li>
            ))}
          </ul>
        ) : (
          null
        )}
      </div>
    </>
  );
};

export default TrainingLibrary;
