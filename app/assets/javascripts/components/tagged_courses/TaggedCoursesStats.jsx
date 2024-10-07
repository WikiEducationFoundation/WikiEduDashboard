import React, { useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { fetchTaggedCoursesStats } from '@actions/tagged_courses_stats_action';
import OverviewStat from '../common/OverviewStats/overview_stat';
import CourseUtils from '../../utils/course_utils';
import Loading from '../common/loading';

const TaggedCoursesStats = () => {
  const dispatch = useDispatch();
  const tagged_courses_stats = useSelector(state => state.taggedCoursesStats);
  const { tag } = useParams();

  const studentsInfo = [[`${tagged_courses_stats.trained_percent_human}%`, I18n.t('users.up_to_date_with_training')]];
  const taggedCoursesUploadsInfo = [
    [`${tagged_courses_stats.uploads_in_use_count}`, I18n.t('metrics.uploads_in_use_count', { count: tagged_courses_stats.uploads_in_use_count })],
    [`${tagged_courses_stats.upload_usage_count}`, I18n.t('metrics.upload_usages_count', { count: tagged_courses_stats.upload_usage_count })]];

  useEffect(() => {
    dispatch(fetchTaggedCoursesStats(tag));
  }, []);

  if (tagged_courses_stats.loading) {
    return <Loading />;
  }

  return (
    <div className="overview container">
      <div className="stat-display">
        <OverviewStat
          id="courses-count"
          className="stat-display__value"
          stat={tagged_courses_stats.courses_count}
          statMsg={CourseUtils.i18n('courses', tagged_courses_stats.course_string_prefix)}
          renderZero={true}
        />
        <OverviewStat
          id="students-count"
          className="stat-display__value"
          stat={tagged_courses_stats.user_count}
          statMsg={CourseUtils.i18n('students', tagged_courses_stats.course_string_prefix)}
          renderZero={true}
          info={studentsInfo}
          infoId="students-count-info"
        />
        <OverviewStat
          id="words-added"
          className="stat-display__value"
          stat={tagged_courses_stats.word_count_human}
          statMsg={I18n.t('metrics.word_count')}
          renderZero={true}
        />
        <OverviewStat
          id="references-added"
          className="stat-display__value"
          stat={tagged_courses_stats.references_count_human}
          statMsg={I18n.t('metrics.references_count')}
          renderZero={true}
          info={I18n.t('metrics.references_doc')}
          infoId="tagged-courses-references-info"
        />
        <OverviewStat
          id="article-views"
          className="stat-display__value"
          stat={tagged_courses_stats.view_sum_human}
          statMsg={I18n.t('metrics.view_count_description')}
          renderZero={true}
        />
        <OverviewStat
          id="articles-edited"
          className="stat-display__value"
          stat={tagged_courses_stats.article_count_human}
          statMsg={I18n.t('metrics.articles_edited')}
          renderZero={true}
        />
        <OverviewStat
          id="articles-created"
          className="stat-display__value"
          stat={tagged_courses_stats.new_article_count_human}
          statMsg={I18n.t('metrics.articles_created')}
          renderZero={true}
        />
        <OverviewStat
          id="common-uploads"
          className="stat-display__value"
          stat={tagged_courses_stats.upload_count_human}
          statMsg={I18n.t('metrics.upload_count')}
          renderZero={true}
          info={taggedCoursesUploadsInfo}
          infoId="tagged-courses-uploads-info"
        />
      </div>
    </div>
  );
};

export default TaggedCoursesStats;
