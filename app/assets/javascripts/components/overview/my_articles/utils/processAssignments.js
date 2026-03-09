import {
  ASSIGNED_ROLE, REVIEWING_ROLE,
  IMPROVING_ARTICLE, NEW_ARTICLE, REVIEWING_ARTICLE
} from '../../../../constants/assignments';
import { groupByAssignmentType } from '../../../util/helpers';

export const getList = (assignments, currentUserId, ROLE) => {
  return assignments.reduce((acc, { article_title, role, user_id, username }) => {
    if (!user_id || role === ROLE || user_id === currentUserId) return acc;
    if (acc[article_title]) {
      acc[article_title].push(username);
    } else {
      acc[article_title] = [username];
    }

    return acc;
  }, {});
};

export const getEditorsList = (assignments, currentUserId) => {
  return getList(assignments, currentUserId, REVIEWING_ROLE);
};

export const getReviewersList = (assignments, currentUserId) => {
  return getList(assignments, currentUserId, ASSIGNED_ROLE);
};

export const sandboxUrl = (course, assignment) => {
  if (assignment.sandbox_url) return assignment.sandbox_url;

  const { username } = assignment;
  let { language, project } = assignment;
  if (!language || !project) {
    language = course.home_wiki.language || 'www';
    project = course.home_wiki.project || 'wikipedia';
  }

  return `https://${language}.${project}.org/wiki/User:${username}/sandbox`;
};

export const addAssignmentCategory = (assignment) => {
  const result = { ...assignment };

  if (assignment.role === ASSIGNED_ROLE) {
    if (!assignment.article_id) {
      result.article_status = NEW_ARTICLE;
    } else {
      result.article_status = IMPROVING_ARTICLE;
    }
  } else {
    result.article_status = REVIEWING_ARTICLE;
  }

  return result;
};

export const isUserSandbox = (assignment) => {
  return assignment.article_title.split(':')[0].toLowerCase() === 'user';
};

export const addSandboxUrl = (assignments, course, user_id) => {
  return (assignment) => {
    const result = {
      ...assignment,
      sandboxUrl: sandboxUrl(course, assignment)
    };

    if (assignment.role === REVIEWING_ROLE) {
      const related = assignments.find(({ article_id, article_title, role, user_id: id }) => {
        return id
          && role === ASSIGNED_ROLE
          && article_id === assignment.article_id
          && article_title === assignment.article_title
          && id !== user_id;
      });

      if (related) {
        result.sandboxUrl = sandboxUrl(course, related);
      }
    }

    return result;
  };
};

// Input : props
export const processAssignments = ({ assignments, course, current_user }) => {
  const { id: userId } = current_user;

  // Backfill Sandbox URLs for assignments
  assignments = assignments.map(addSandboxUrl(assignments, course, userId));

  // Add editors
  const editorsList = getEditorsList(assignments, userId);
  assignments = assignments.map((assignment) => {
    assignment.editors = editorsList[assignment.article_title] || null;
    return assignment;
  });

  // Add reviewers
  const reviewersList = getReviewersList(assignments, userId);
  assignments = assignments.map((assignment) => {
    assignment.reviewers = reviewersList[assignment.article_title] || null;
    return assignment;
  });

  const {
    assigned, reviewing,
    unassigned, reviewable, assignable
  } = groupByAssignmentType(assignments, userId);

  const all = assigned.concat(reviewing).map(addAssignmentCategory);

  return {
    assigned,
    reviewing,
    unassigned,
    reviewable,
    assignable,
    all
  };
};
