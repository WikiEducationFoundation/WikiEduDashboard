import { createSelector } from 'reselect';
import _ from 'lodash';
import { getFiltered } from '../utils/model_utils';
import { STUDENT_ROLE, INSTRUCTOR_ROLE, ONLINE_VOLUNTEER_ROLE, CAMPUS_VOLUNTEER_ROLE, STAFF_ROLE, fetchStates } from '../constants';
import UserUtils from '../utils/user_utils.js';
import { PageAssessmentGrades } from '../utils/article_finder_language_mappings.js';

const getUsers = state => state.users.users;
const getCurrentUserFromHtml = state => state.currentUserFromHtml;
const getCourseCampaigns = state => state.campaigns.campaigns;
const getAllCampaigns = state => state.campaigns.all_campaigns;
const getUserCourses = state => state.userCourses.userCourses;
const getAllEditedArticles = state => state.articles.articles;
const getWikiFilter = state => state.articles.wikiFilter;
const getNewnessFilter = state => state.articles.newnessFilter;
const getAlerts = state => state.alerts.alerts;
const getAlertFilters = state => state.alerts.selectedFilters;
const getArticleFinderState = state => state.articleFinder;
const getUploads = state => state.uploads.uploads;
const getUploadFilters = state => state.uploads.selectedFilters;
const getTags = state => state.tags.tags;
const getAllTags = state => state.tags.allTags;
const getWeeks = state => state.timeline.weeks;
const getBlocks = state => state.timeline.blocks;
const getCourseType = state => state.course.type;
const getTraining = state => state.training;

export const getInstructorUsers = createSelector(
  [getUsers], users => _.sortBy(getFiltered(users, { role: INSTRUCTOR_ROLE }), 'enrolled_at')
);

export const getStudentUsers = createSelector(
  [getUsers], users => getFiltered(users, { role: STUDENT_ROLE })
);

export const getStudentCount = createSelector(
  [getStudentUsers], users => users.length
);

export const getStaffUsers = createSelector(
  [getUsers], users => _.sortBy(getFiltered(users, { role: STAFF_ROLE }), 'enrolled_at')
);

export const getProgramManagers = createSelector(
  [getStaffUsers], users => getFiltered(users, { program_manager: true })
);

export const getContentExperts = createSelector(
  [getStaffUsers], users => getFiltered(users, { content_expert: true })
);

export const getOnlineVolunteerUsers = createSelector(
  [getUsers], users => _.sortBy(getFiltered(users, { role: ONLINE_VOLUNTEER_ROLE }), 'enrolled_at')
);

export const getCampusVolunteerUsers = createSelector(
  [getUsers], users => _.sortBy(getFiltered(users, { role: CAMPUS_VOLUNTEER_ROLE }), 'enrolled_at')
);

export const getCurrentUser = createSelector(
  [getCurrentUserFromHtml, getUsers], (currentUserFromHtml, users) => {
    const currentUserFromUsers = getFiltered(users, { id: currentUserFromHtml.id })[0];
    const currentUser = currentUserFromUsers || currentUserFromHtml;
    const userRoles = UserUtils.userRoles(currentUser, users);
    return { ...currentUser, ...userRoles };
  }
);

export const getAvailableCampaigns = createSelector(
  [getCourseCampaigns, getAllCampaigns], (campaigns, allCampaigns) => {
    campaigns = campaigns.map(campaign => campaign.title);
    return _.difference(allCampaigns, campaigns);
  }
);

export const getAvailableTags = createSelector(
  [getTags, getAllTags], (tags, allTags) => {
    tags = tags.map(tag => tag.tag);
    allTags = _.uniq(allTags);
    return _.difference(allTags, tags);
  }
);


export const getCloneableCourses = createSelector(
  [getUserCourses], (userCourses) => {
    return getFiltered(userCourses, { cloneable: true });
  }
);

export const getWikiArticles = createSelector(
  [getAllEditedArticles, getWikiFilter], (editedArticles, wikiFilter) => {
    if (wikiFilter === null) {
      return editedArticles;
    }
    return getFiltered(editedArticles, { ...wikiFilter });
  }
);

export const getArticlesByNewness = createSelector(
  [getWikiArticles, getNewnessFilter], (articles, newnessFilter) => {
    switch (newnessFilter) {
      case 'new':
        return articles.filter(a => a.new_article);
      case 'existing':
        return articles.filter(a => !a.new_article);
      default:
        return articles;
    }
  }
);

export const getFilteredAlerts = createSelector(
  [getAlerts, getAlertFilters], (alerts, alertFilters) => {
    if (!alertFilters.length) { return alerts; }
    return _.filter(alerts, alert => _.includes(alertFilters, alert.type));
  }
);

export const getFilteredArticleFinder = createSelector(
  [getArticleFinderState], (articleFinder) => {
    return _.pickBy(articleFinder.articles, (article) => {
      if (article.grade && !_.includes(Object.keys(PageAssessmentGrades[articleFinder.home_wiki.language]), article.grade)) {
        return false;
      }
      let quality;
      if (article.grade && article.revScore) {
        quality = Math.max(article.revScore, PageAssessmentGrades[articleFinder.home_wiki.language][article.grade].score);
      } else if (article.grade) {
        quality = PageAssessmentGrades[articleFinder.home_wiki.language][article.grade].score;
      } else if (article.revScore) {
        quality = article.revScore;
      } else {
        quality = 0;
      }
      const qualityFilter = articleFinder.article_quality;
      if (fetchStates[article.fetchState] >= fetchStates.PAGEVIEWS_RECEIVED && article.pageviews < articleFinder.min_views) {
        return false;
      }
      if (fetchStates[article.fetchState] >= fetchStates.REVISIONSCORE_RECEIVED && quality > qualityFilter) {
        return false;
      }
      return true;
    });
  }
);

export const getFilteredUploads = createSelector(
  [getUploads, getUploadFilters], (uploads, uploadFilters) => {
    if (!uploadFilters.length) { return uploads; }
    return _.filter(uploads, upload => _.includes(uploadFilters, upload.uploader));
  }
);

export const getWeeksArray = createSelector(
  [getWeeks, getBlocks], (weeks, blocks) => {
    const weeksArray = [];
    const weekIds = Object.keys(weeks);
    const blocksByWeek = {};
    Object.keys(blocks).forEach((blockId) => {
      const block = blocks[blockId];
      if (blocksByWeek[block.week_id]) {
        blocksByWeek[block.week_id].push(block);
      } else {
        blocksByWeek[block.week_id] = [block];
      }
    });

    weekIds.forEach((weekId) => {
      const newWeek = weeks[weekId];
      newWeek.blocks = blocksByWeek[weekId] || [];
      weeksArray.push(newWeek);
    });

    return weeksArray;
  }
);

export const getAvailableTrainingModules = createSelector(
  [getCourseType, getTraining], (courseType, training) => {
    // We only do filtering for ClassroomProgramCourse type.
    if (courseType !== 'ClassroomProgramCourse') {
      return training.modules;
    }
    // Find the Student library that we want to filter by.
    const studentsLibrary = training.libraries.find(library => library.slug === 'students');
    if (!studentsLibrary) { return training.modules; }

    // Only include modules that are part of the Student library.
    const studentModules = training.modules.filter(module => studentsLibrary.modules.includes(module.slug));
    return studentModules;
  }
);
