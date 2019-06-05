import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import AssignCell from '../students/assign_cell.jsx';
import MyAssignmentsList from './my_assignments_list.jsx';
import { fetchAssignments } from '../../actions/assignment_actions';
import { getFiltered } from '../../utils/model_utils';

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

  render() {
    const { assignments, current_user } = this.props;
    const user_id = current_user.id;
    const assignOptions = { user_id, role: 0 };
    const reviewOptions = { user_id, role: 1 };

    const assignmentsWithSandboxes = assignments.map((article) => {
      if (article.role === 0) return article;
      const related = assignments.find((assignment) => {
        return assignment.article_id === article.article_id
          && assignment.user_id
          && assignment.user_id !== user_id;
      });
      return {
        ...article,
        sandbox_url: `https://en.wikipedia.org/wiki/User:${related.username}/sandbox`
      };
    });

    const assigned = getFiltered(assignmentsWithSandboxes, assignOptions);
    const reviewing = getFiltered(assignmentsWithSandboxes, reviewOptions);
    const all = assigned.concat(reviewing);
    const assignmentCount = all.length;

    const { course, wikidataLabels } = this.props;
    const assignmentElements = <MyAssignmentsList
      assignments={all}
      count={assignmentCount}
      course={course}
      current_user={current_user}
      wikidataLabels={wikidataLabels}
    />;

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
              id="user_assigned"
              course={this.props.course}
              role={0}
              editable
              current_user={current_user}
              student={current_user}
              assignments={assigned}
              prefix={I18n.t('users.my_assigned')}
              tooltip_message={I18n.t('assignments.assign_tooltip')}
              wikidataLabels={this.props.wikidataLabels}
            />
            <AssignCell
              id="user_reviewing"
              course={this.props.course}
              role={1}
              editable
              current_user={current_user}
              student={current_user}
              assignments={reviewing}
              prefix={I18n.t('users.my_reviewing')}
              tooltip_message={I18n.t('assignments.review_tooltip')}
              wikidataLabels={this.props.wikidataLabels}
            />
            <Link to={`/courses/${this.props.course.slug}/article_finder`}><button className="button border small ml1">Find Articles</button></Link>
          </div>
        </div>
        {assignmentElements}
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
