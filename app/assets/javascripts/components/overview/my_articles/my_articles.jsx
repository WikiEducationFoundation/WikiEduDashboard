import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import AssignCell from '../../students/assign_cell.jsx';
import MyAssignmentsList from './my_assignments_list.jsx';
import { fetchAssignments } from '../../../actions/assignment_actions';
import {
  ASSIGNED_ROLE, REVIEWING_ROLE,
  IMPROVING_ARTICLE, NEW_ARTICLE, REVIEWING_ARTICLE
} from '../../../constants/assignments';
import { groupByAssignmentType } from '../../util/helpers';

export const MyArticles = createReactClass({
  displayName: 'MyArticles',

  propTypes: {
    course: PropTypes.object,
    current_user: PropTypes.object,
    course_id: PropTypes.string,
    assignments: PropTypes.array,
    loadingAssignments: PropTypes.bool
  },

  componentDidMount() {
    if (this.props.loadingAssignments) {
      this.props.fetchAssignments(this.props.course_id);
    }
  },

  getList(assignments, currentUserId, ROLE) {
    return assignments.reduce((acc, { article_title, role, user_id, username }) => {
      if (!user_id || role === ROLE || user_id === currentUserId) return acc;
      if (acc[article_title]) {
        acc[article_title].push(username);
      } else {
        acc[article_title] = [username];
      }

      return acc;
    }, {});
  },

  getEditorsList(assignments, currentUserId) {
    return this.getList(assignments, currentUserId, REVIEWING_ROLE);
  },

  getReviewersList(assignments, currentUserId) {
    return this.getList(assignments, currentUserId, ASSIGNED_ROLE);
  },

  sandboxUrl(course, assignment) {
    if (assignment.sandbox_url) return assignment.sandbox_url;

    const { username } = assignment;
    let { language, project } = assignment;
    if (!language || !project) {
      language = course.home_wiki.language || 'www';
      project = course.home_wiki.project || 'wikipedia';
    }

    return `https://${language}.${project}.org/wiki/User:${username}/sandbox`;
  },

  addAssignmentCategory(assignment) {
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
  },

  addSandboxUrl(assignments, course, user_id) {
    return (assignment) => {
      const result = {
        ...assignment,
        sandboxUrl: this.sandboxUrl(course, assignment)
      };

      if (assignment.role === REVIEWING_ROLE) {
        const related = assignments.find(({ article_id, user_id: id }) => {
          return id && article_id === assignment.article_id && id !== user_id;
        });

        if (related) {
          result.sandboxUrl = this.sandboxUrl(course, related);
        }
      }

      return result;
    };
  },

  render() {
    let { assignments } = this.props;
    const { course, current_user, wikidataLabels } = this.props;
    const user_id = current_user.id;

    // Backfill Sandbox URLs for assignments
    const addSandboxUrl = this.addSandboxUrl(assignments, course, user_id);
    assignments = assignments.map(addSandboxUrl);

    // Add editors
    const editorsList = this.getEditorsList(assignments, user_id);
    assignments = assignments.map((assignment) => {
      assignment.editors = editorsList[assignment.article_title] || null;
      return assignment;
    });

    // Add reviewers
    const reviewersList = this.getReviewersList(assignments, user_id);
    assignments = assignments.map((assignment) => {
      assignment.reviewers = reviewersList[assignment.article_title] || null;
      return assignment;
    });

    const {
      assigned, reviewing,
      unassigned, reviewable
    } = groupByAssignmentType(assignments, user_id);

    const all = assigned.concat(reviewing).map(this.addAssignmentCategory);

    return (
      <div className="module my-articles">
        <div className="section-header my-articles-header">
          <h3>{I18n.t('courses.my_articles')}</h3>
          <div className="controls">
            <AssignCell
              assignments={assigned}
              editable
              course={this.props.course}
              current_user={current_user}
              hideAssignedArticles
              id="user_assigned"
              prefix={I18n.t('users.my_assigned')}
              role={ASSIGNED_ROLE}
              student={current_user}
              tooltip_message={I18n.t('assignments.assign_tooltip')}
              unassigned={unassigned}
              wikidataLabels={this.props.wikidataLabels}
            />
            <AssignCell
              assignments={reviewing}
              course={this.props.course}
              current_user={current_user}
              editable
              hideAssignedArticles
              id="user_reviewing"
              prefix={I18n.t('users.my_reviewing')}
              role={REVIEWING_ROLE}
              student={current_user}
              tooltip_message={I18n.t('assignments.review_tooltip')}
              unassigned={reviewable}
              wikidataLabels={this.props.wikidataLabels}
            />
            <Link to={`/courses/${this.props.course.slug}/article_finder`}>
              <button className="button border small assign-button link">Find Articles</button>
            </Link>
          </div>
        </div>
        <MyAssignmentsList
          assignments={all}
          course={course}
          current_user={current_user}
          wikidataLabels={wikidataLabels}
        />
      </div>
    );
  }
});

const mapStateToProps = state => ({
  assignments: state.assignments.assignments,
  loadingAssignments: state.assignments.loading,
  wikidataLabels: state.wikidataLabels.labels
});

const mapDispatchToProps = {
  fetchAssignments
};

export default connect(mapStateToProps, mapDispatchToProps)(MyArticles);
