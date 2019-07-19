import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import MainspaceChecklist from '../common/mainspace_checklist.jsx';
import FinalArticleChecklist from '../common/final_article_checklist.jsx';
import PeerReviewChecklist from '../common/peer_review_checklist.jsx';
import CourseUtils from '../../utils/course_utils.js';
import Feedback from '../common/feedback.jsx';

import { initiateConfirm } from '../../actions/confirm_actions';
import { deleteAssignment } from '../../actions/assignment_actions';

export const MyAssignment = createReactClass({
  displayName: 'MyAssignment',

  propTypes: {
    assignment: PropTypes.object.isRequired,
    current_user: PropTypes.object,
    course: PropTypes.object.isRequired,
    username: PropTypes.string,
    wikidataLabels: PropTypes.object.isRequired
  },

  isEnglishWikipedia() {
    if (this.props.course.home_wiki.language === 'en' && this.props.course.home_wiki.project === 'wikipedia') {
      if (typeof this.props.assignment.language === 'undefined') {
        return true;
      }
    }
    if (this.props.assignment.language === 'en' && this.props.assignment.project === 'wikipedia') {
      return true;
    }
    return false;
  },

  unassign(assignment) {
    this.props.initiateConfirm(I18n.t('assignments.confirm_deletion'), () => {
      this.props.deleteAssignment({ course_slug: this.props.course.id, ...assignment });
    });
  },

  render() {
    const { assignment, username } = this.props;
    const isEnglishWikipedia = this.isEnglishWikipedia();
    let articleTitle = assignment.article_title;
    let checklist;
    let pageviews;
    let feedback;
    if (assignment.article_id) {
      const article = CourseUtils.articleFromTitleInput(assignment.article_url);
      const label = this.props.wikidataLabels[article.title.replace('www:wikidata', '')];
      articleTitle = CourseUtils.formattedArticleTitle(article, this.props.course.home_wiki, label);
      const pageviewUrl = `https://tools.wmflabs.org/pageviews/?project=${article.language}.${article.project}.org&platform=all-access&agent=user&range=latest-90&pages=${article.title}`;
      pageviews = <a className="button dark small" href={pageviewUrl} target="_blank">Pageviews</a>;
    }

    // Assigned article that does not yet exist in mainspace
    if (assignment.role === 0 && !assignment.article_id) {
      if (isEnglishWikipedia) {
        checklist = <MainspaceChecklist />;
        feedback = <Feedback assignment={assignment} username={username} current_user={this.props.current_user} />;
      }
    // Assigned article that already exists
    } else if (assignment.role === 0) {
      if (isEnglishWikipedia) {
        checklist = <FinalArticleChecklist />;
        feedback = <Feedback assignment={assignment} username={username} current_user={this.props.current_user} />;
      }
    // Review assignment
    } else if (isEnglishWikipedia) {
      checklist = <PeerReviewChecklist />;
    }

    return (
      <div className="my-assignment mb1">
        <span className="my-assignment-title" >
          {articleTitle} •&nbsp;
          <a href={assignment.sandboxUrl} target="_blank">Sandbox</a> •&nbsp;
          <a href={assignment.article_url}>Article</a>
        </span>
        <div className="my-assignment-button">
          <div><button onClick={() => this.unassign(assignment)} className="button danger small">Remove</button></div>
          {feedback}
          {pageviews}
          {checklist}
        </div>
      </div>
    );
  }
});

const mapDispatchToProps = {
  initiateConfirm,
  deleteAssignment
};

export default connect(null, mapDispatchToProps)(MyAssignment);
