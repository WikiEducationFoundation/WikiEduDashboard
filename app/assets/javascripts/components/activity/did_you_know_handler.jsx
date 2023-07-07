import React, { useEffect, useRef } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import ActivityTable from './activity_table.jsx';
import { fetchDYKArticles, sortDYKArticles } from '../../actions/did_you_know_actions.js';

const NO_ACTIVITY_MESSAGE = I18n.t('recent_activity.no_dyk_eligible');

const HEADERS = [
  { title: I18n.t('recent_activity.article_title'), key: 'title' },
  { title: I18n.t('recent_activity.revision_score'), key: 'revision_score', style: { width: 180 } },
  { title: I18n.t('recent_activity.revision_author'), key: 'username', style: { minWidth: 142 } },
  { title: I18n.t('recent_activity.revision_datetime'), key: 'datetime', style: { width: 200 } }
];

const DidYouKnowHandler = () => {
  const myCoursesRef = useRef(null);

  const dispatch = useDispatch();
  const articles = useSelector(state => state.didYouKnow.articles);
  const loading = useSelector(state => state.didYouKnow.loading);

  useEffect(() => {
    dispatch(fetchDYKArticles());
  }, []);

  const setCourseScope = (e) => {
    const scoped = e.target.checked;
    dispatch(fetchDYKArticles({ scoped }));
  };

  return (
    <div>
      <label>
        <input
          ref={myCoursesRef}
          type="checkbox"
          onChange={setCourseScope}
        />
        {I18n.t('recent_activity.show_courses')}
      </label>
      <ActivityTable
        loading={loading}
        activity={articles}
        headers={HEADERS}
        noActivityMessage={NO_ACTIVITY_MESSAGE}
        onSort={dataSortKey => dispatch(sortDYKArticles(dataSortKey))}
      />
    </div>
  );
};

DidYouKnowHandler.propTypes = {
  fetchDYKArticles: PropTypes.func,
  articles: PropTypes.array,
  loading: PropTypes.bool
};

export default (DidYouKnowHandler);
