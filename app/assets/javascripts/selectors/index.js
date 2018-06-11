import { createSelector } from 'reselect';
import _ from 'lodash';
import { getFiltered } from '../utils/model_utils';
import { STUDENT_ROLE, INSTRUCTOR_ROLE, ONLINE_VOLUNTEER_ROLE, CAMPUS_VOLUNTEER_ROLE, STAFF_ROLE, WP10Weights, fetchStates } from '../constants';
import UserUtils from '../utils/user_utils.js';

const getUsers = state => state.users.users;
const getCurrentUserFromHtml = state => state.currentUserFromHtml;
const getCourseCampaigns = state => state.campaigns.campaigns;
const getAllCampaigns = state => state.campaigns.all_campaigns;
const getUserCourses = state => state.userCourses.userCourses;
const getAllEditedArticles = state => state.articles.articles;
const getWikiFilter = state => state.articles.wikiFilter;
const getAlerts = state => state.alerts.alerts;
const getAlertFilters = state => state.alerts.selectedFilters;
const getArticleFinderState = state => state.articleFinder;

export const getInstructorUsers = createSelector(
  [getUsers], (users) => _.sortBy(getFiltered(users, { role: INSTRUCTOR_ROLE }), 'enrolled_at')
);

export const getStudentUsers = createSelector(
  [getUsers], (users) => getFiltered(users, { role: STUDENT_ROLE })
);

export const getStudentCount = createSelector(
  [getStudentUsers], (users) => users.length
);

export const getStaffUsers = createSelector(
  [getUsers], (users) => _.sortBy(getFiltered(users, { role: STAFF_ROLE }), 'enrolled_at')
);

export const getProgramManagers = createSelector(
  [getStaffUsers], (users) => getFiltered(users, { program_manager: true })
);

export const getContentExperts = createSelector(
  [getStaffUsers], (users) => getFiltered(users, { content_expert: true })
);

export const getOnlineVolunteerUsers = createSelector(
  [getUsers], (users) => _.sortBy(getFiltered(users, { role: ONLINE_VOLUNTEER_ROLE }), 'enrolled_at')
);

export const getCampusVolunteerUsers = createSelector(
  [getUsers], (users) => _.sortBy(getFiltered(users, { role: CAMPUS_VOLUNTEER_ROLE }), 'enrolled_at')
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

export const getFilteredAlerts = createSelector(
  [getAlerts, getAlertFilters], (alerts, alertFilters) => {
    if (!alertFilters.length) { return alerts; }
    return _.filter(alerts, (alert) => _.includes(alertFilters, alert.type));
  }
);

export const getFilteredArticleFinder = createSelector(
  [getArticleFinderState], (articleFinder) => {
    return _.pickBy(articleFinder.articles, (article) => {
      const quality = Math.max(article.revScore, WP10Weights[article.grade]);
      const qualityFilter = articleFinder.article_quality;
      if (article.grade && !_.includes(Object.keys(WP10Weights), article.grade)) {
        return false;
      }
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
