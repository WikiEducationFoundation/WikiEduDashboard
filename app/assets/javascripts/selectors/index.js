import { createSelector } from 'reselect';
import { sortBy, difference, uniq, filter, includes, pickBy, find } from 'lodash-es';
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
const getTrackedStatusFilter = state => state.articles.trackedStatusFilter;
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
const getValidations = state => state.validations.validations;
const getValidationErrors = state => state.validations.errorQueue;
const getCourse = state => state.course;
const getTickets = state => state.tickets;

export const getInstructorUsers = createSelector(
  [getUsers], users => sortBy(getFiltered(users, { role: INSTRUCTOR_ROLE }), 'enrolled_at')
);

export const getStudentUsers = createSelector(
  [getUsers], users => getFiltered(users, { role: STUDENT_ROLE })
);

export const getStudentCount = createSelector(
  [getStudentUsers], users => users.length
);

export const getStaffUsers = createSelector(
  [getUsers], users => sortBy(getFiltered(users, { role: STAFF_ROLE }), 'enrolled_at')
);

export const getProgramManagers = createSelector(
  [getStaffUsers], users => getFiltered(users, { program_manager: true })
);

export const getContentExperts = createSelector(
  [getStaffUsers], users => getFiltered(users, { content_expert: true })
);

export const getOnlineVolunteerUsers = createSelector(
  [getUsers], users => sortBy(getFiltered(users, { role: ONLINE_VOLUNTEER_ROLE }), 'enrolled_at')
);

export const getCampusVolunteerUsers = createSelector(
  [getUsers], users => sortBy(getFiltered(users, { role: CAMPUS_VOLUNTEER_ROLE }), 'enrolled_at')
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
    return difference(allCampaigns, campaigns);
  }
);

export const getAvailableTags = createSelector(
  [getTags, getAllTags], (tags, allTags) => {
    tags = tags.map(tag => tag.tag);
    allTags = uniq(allTags);
    return difference(allTags, tags);
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

export const getArticlesByTrackedStatus = createSelector(
  [getArticlesByNewness, getTrackedStatusFilter], (articles, trackedStatusFilter) => {
    switch (trackedStatusFilter) {
      case 'tracked':
        return articles.filter(a => a.tracked);
      case 'untracked':
        return articles.filter(a => !a.tracked);
      default:
        return articles;
    }
  }
);

export const getFilteredAlerts = createSelector(
  [getAlerts, getAlertFilters], (alerts, alertFilters) => {
    if (!alertFilters.length) { return alerts; }
    const alertTypes = alertFilters.map(_filter => _filter.value);
    return filter(alerts, alert => includes(alertTypes, alert.type));
  }
);

export const getFilteredArticleFinder = createSelector(
  [getArticleFinderState], (articleFinder) => {
    return pickBy(articleFinder.articles, (article) => {
      const language = articleFinder.home_wiki.language;
      const project = articleFinder.home_wiki.project;
      if (article.grade && !includes(Object.keys(PageAssessmentGrades[project][language]), article.grade)) {
        return false;
      }
      let quality;
      if (article.grade && article.revScore) {
        quality = Math.max(article.revScore, PageAssessmentGrades[project][language][article.grade].score);
      } else if (article.grade) {
        quality = PageAssessmentGrades[project][language][article.grade].score;
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
    const uploaders = uploadFilters.map(_filter => _filter.value);
    return filter(uploads, upload => includes(uploaders, upload.uploader));
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

export const isValid = createSelector(
  [getValidations], (validations) => {
    // If any validation is not valid, return false.
    const invalidValue = find(validations, (value) => { return value.valid === false; });
    if (invalidValue) { return false; }
    return true;
  }
);

export const firstValidationErrorMessage = createSelector(
  [getValidations, getValidationErrors], (validations, validationErrors) => {
    if (validationErrors.length > 0) {
      return validations[validationErrors[0]].message;
    }
    return null;
  }
);

export const editPermissions = createSelector(
  [getCourse, getCurrentUser], (course, user) => {
    if (!user.isAdvancedRole) { return false; }
    return user.isAdmin || !course.closed;
  }
);

export const getFilteredTickets = createSelector(
  [getTickets], (tickets) => {
    const ownerIds = tickets.filters.owners.map(_filter => _filter.value);
    const statuses = tickets.filters.statuses.map(_filter => parseInt(_filter.value));

    let ownerFilter = ticket => ticket;
    let statusFilter = ticket => ticket;
    if (ownerIds.length) {
      ownerFilter = ticket => ownerIds.includes(ticket.owner.id);
    }
    if (statuses.length) {
      statusFilter = ticket => statuses.includes(ticket.status);
    }

    return tickets.all
      .filter(ownerFilter)
      .filter(statusFilter);
  }
);

export const getTicketsById = createSelector(
  [getTickets], (tickets) => {
    return tickets.all.reduce((acc, ticket) => ({ ...acc, [ticket.id]: ticket }), {});
  }
);
