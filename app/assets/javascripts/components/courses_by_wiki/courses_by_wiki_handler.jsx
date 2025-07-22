import React, { useEffect } from 'react';
import CourseWikiList from './wiki_course_list';
import CampaignStats from '../campaign/campaign_stats';
import { useParams } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { fetchCoursesFromWiki } from '../../actions/course_actions';
import { getWikiObjectFromURL } from '../../utils/revision_utils';
import Loading from '../common/loading';

const CoursesByWikiHandler = () => {
  const { wiki_url } = useParams();
  const { courses, isLoaded, sort, statistics, wiki_domain } = useSelector(state => state.wiki_courses);
  const dispatch = useDispatch();
  useEffect(() => {
    dispatch(fetchCoursesFromWiki(getWikiObjectFromURL(wiki_url)));
  }, []);

  useEffect(() => {
    document.title = `${document.title} - ${wiki_domain}`;
  }, [wiki_domain]);

  if (!isLoaded) {
    return <Loading />;
  }
  return (
    <header className="main-page">
      <div className="container">
        <h1>
          {wiki_domain}
        </h1>
      </div>
      <CampaignStats campaign={statistics} />
      <CourseWikiList sort={sort} courses={courses}/>
    </header>
  );
};

export default CoursesByWikiHandler;
