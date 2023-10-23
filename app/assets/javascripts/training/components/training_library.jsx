import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useParams } from 'react-router-dom';
import { fetchTrainingLibrary } from '../../actions/training_actions';

const TrainingLibrary = () => {
  const { library_id } = useParams();
  const library = useSelector(state => state.training.library);
  const currentUser = useSelector(state => state.currentUser);
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(fetchTrainingLibrary(library_id));
  }, [dispatch, library_id]);

  if (!library) {
    return <div>Loading...</div>;
  }

  return (
    <div className="training__section-overview container">
      <section className="training__header">
        <h1>{library.name}</h1>
        <p>{library.introduction}</p>
      </section>
      {library.categories ? (
        <ul className="training__categories">
          {library.categories.map((libCategory, index) => (
            <li key={index}>
              <div className="training__category__header">
                <h1 className="h3">{libCategory.title}</h1>
                <p>{libCategory.description}</p>
                {library.wiki_page && (
                  <div className="training__category__source">
                    <a href={`https://meta.wikimedia.org/wiki/${library.wiki_page}`}>
                      View Library Source
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
                        {currentUser && libModule.slug && (
                        <span className="pull-right action-card-title__completion">
                            {libModule.slug}
                        </span>
                        )}
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
        <p>No categories available.</p>
      )}
    </div>
  );
};

export default TrainingLibrary;
