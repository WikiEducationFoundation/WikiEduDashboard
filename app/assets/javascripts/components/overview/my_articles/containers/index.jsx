import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

// components
import MyArticlesNoAssignmentMessage from '@components/overview/my_articles/components/NoAssignmentMessage.jsx';
import MyArticlesHeader from '@components/overview/my_articles/components/Header.jsx';
import MyArticlesCategories from '@components/overview/my_articles/components/Categories/Categories.jsx';

// actions
import { fetchAssignments } from '~/app/assets/javascripts/actions/assignment_actions';

// helper functions
import { processAssignments } from '@components/overview/my_articles/utils/processAssignments';

export class MyArticlesContainer extends React.Component {
  componentDidMount() {
    if (this.props.loading) {
      this.props.fetchAssignments(this.props.course.slug);
    }
  }

  render() {
    const {
      course, current_user, loading, wikidataLabels
    } = this.props;

    const {
      assigned,
      reviewing,
      unassigned,
      reviewable,
      all
    } = processAssignments(this.props);

    if (loading || !current_user.isStudent) return null;
    let noArticlesMessage;
    if (!assigned.length && current_user.isStudent) {
      if (Features.wikiEd) {
        noArticlesMessage = <MyArticlesNoAssignmentMessage />;
      } else {
        noArticlesMessage = <p id="no-assignment-message">{I18n.t('assignments.none_short')}</p>;
      }
    }

    return (
      <div>
        <div className="module my-articles">
          <MyArticlesHeader
            assigned={assigned}
            course={course}
            current_user={current_user}
            reviewable={reviewable}
            reviewing={reviewing}
            unassigned={unassigned}
            wikidataLabels={wikidataLabels}
          />
          <MyArticlesCategories
            assignments={all}
            course={course}
            current_user={current_user}
            loading={loading}
            wikidataLabels={wikidataLabels}
          />
          {noArticlesMessage}
        </div>
      </div>
    );
  }
}

MyArticlesContainer.propTypes = {
  // props
  assignments: PropTypes.array.isRequired,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object,
  loading: PropTypes.bool.isRequired,
  wikidataLabels: PropTypes.object.isRequired,

  // actions
  fetchAssignments: PropTypes.func.isRequired,
};

const mapStateToProps = state => ({
  assignments: state.assignments.assignments,
  course: state.course,
  loading: state.assignments.loading,
  wikidataLabels: state.wikidataLabels
});

const mapDispatchToProps = { fetchAssignments };

export default connect(mapStateToProps, mapDispatchToProps)(MyArticlesContainer);
