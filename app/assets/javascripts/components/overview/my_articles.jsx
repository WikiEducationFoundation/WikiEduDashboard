import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import AssignCell from '../students/assign_cell.jsx';
import MyAssignmentsList from './my_assignments_list.jsx';
import { fetchAssignments } from '../../actions/assignment_actions';
import { getFiltered } from '../../utils/model_utils';
import {
  ASSIGNED_ROLE, REVIEWING_ROLE,
  IMPROVING_ARTICLE, NEW_ARTICLE, REVIEWING_ARTICLE
} from '../../constants/assignments';

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

  sandboxUrl(course, username) {
    const { language, project } = course.home_wiki;
    return `https://${language}.${project}.org/wiki/User:${username}/sandbox`;
  },

  addAssignmentCategory(assignment) {
    const result = { ...assignment };

    if (assignment.role === ASSIGNED_ROLE) {
      if (!assignment.article_id) {
        result.status = NEW_ARTICLE;
      } else {
        result.status = IMPROVING_ARTICLE;
      }
    } else {
      result.status = REVIEWING_ARTICLE;
    }

    return result;
  },

  addSandboxUrl(assignments, course, user_id) {
    return (assignment) => {
      const result = {
        ...assignment,
        sandboxUrl: this.sandboxUrl(course, assignment.username)
      };

      if (assignment.role === REVIEWING_ROLE) {
        const related = assignments.find(({ article_id, user_id: id }) => {
          return id && article_id === assignment.article_id && id !== user_id;
        });

        if (related) {
          result.sandboxUrl = this.sandboxUrl(course, related.username);
        }
      }

      return result;
    };
  },

  render() {
    const { assignments, course, current_user, wikidataLabels } = this.props;
    const user_id = current_user.id;

    const addSandboxUrl = this.addSandboxUrl(assignments, course, user_id);
    const updatedAssignments = assignments.map(addSandboxUrl);

    const unassignedOptions = { user_id: null, role: ASSIGNED_ROLE };
    const unassigned = getFiltered(updatedAssignments, unassignedOptions);

    const assignOptions = { user_id, role: ASSIGNED_ROLE };
    const assigned = getFiltered(updatedAssignments, assignOptions);

    const reviewOptions = { user_id, role: REVIEWING_ROLE };
    const reviewing = getFiltered(updatedAssignments, reviewOptions);

    // To find articles that are able to be reviewed...
    const assignedArticleIds = assigned.map(({ article_id: id }) => id);
    const reviewingArticleIds = reviewing.map(({ article_id: id }) => id);
    const reviewable = updatedAssignments.filter((assignment) => {
      return assignment.user_id // ...the article must have a user_id
             // which shouldn't match the current user's id
             && assignment.user_id !== user_id
             // and should not be an article that is assigned to them
             && !assignedArticleIds.includes(assignment.article_id)
             // and should not be an article they are already reviewing
             && !reviewingArticleIds.includes(assignment.article_id);
    });

    const all = assigned.concat(reviewing).map(this.addAssignmentCategory);
    const assignmentCount = all.length;

    let findYourArticleTraining;
    if (Features.wikiEd && !assignmentCount) {
      findYourArticleTraining = (
        <a href="/training/students/finding-your-article" target="_blank" className="button ghost-button small">
          How to find an article
        </a>
      );
    }

    return (
      <div className="module my-articles">
        <div className="section-header my-articles-header">
          <h3>{I18n.t('courses.my_articles')}</h3>
          <div className="controls">
            {findYourArticleTraining}
            <AssignCell
              assignments={assigned}
              editable
              course={this.props.course}
              current_user={current_user}
              hideAssignedArticles
              id="user_assigned"
              prefix={I18n.t('users.my_assigned')}
              role={0}
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
              role={1}
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
