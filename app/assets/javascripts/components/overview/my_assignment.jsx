import React from 'react';
import MainspaceChecklist from '../common/mainspace_checklist.jsx';
import FinalArticleChecklist from '../common/final_article_checklist.jsx';
import PeerReviewChecklist from '../common/peer_review_checklist.jsx';
import CourseUtils from '../../utils/course_utils.js';
import Feedback from '../common/feedback.jsx';

const MyAssignment = React.createClass({
  displayName: 'MyAssignment',

  propTypes: {
    assignment: React.PropTypes.object.isRequired,
    course: React.PropTypes.object.isRequired,
    last: React.PropTypes.bool
  },

  isEnglishWikipedia() {
    if (this.props.course.home_wiki.language === 'en' && this.props.course.home_wiki.project === 'wikipedia') {
      return true;
    }
    if (this.props.assignment.language === 'en' && this.props.assignment.project === 'wikipedia') {
      return true;
    }
    return false;
  },

  render() {
    const isEnglishWikipedia = this.isEnglishWikipedia();
    let assignmentType;
    let checklist;
    let sandbox;
    let sandboxTalk;
    let pageviews;
    let feedback;
    if (this.props.assignment.article_id) {
      const article = CourseUtils.articleFromTitleInput(this.props.assignment.article_url);
      const pageviewUrl = `https://tools.wmflabs.org/pageviews/?project=${article.language}.${article.project}.org&platform=all-access&agent=user&range=latest-90&pages=${article.title}`;
      pageviews = <a className="button dark small" href={pageviewUrl} target="_blank">Pageviews</a>;
    }

    if (this.props.assignment.role === 0 && isEnglishWikipedia) {
      feedback = <Feedback />;
    }

    // Assigned article that does not yet exist in mainspace
    if (this.props.assignment.role === 0 && !this.props.assignment.article_id) {
      assignmentType = 'Creating a new article: ';
      if (isEnglishWikipedia) {
        checklist = <MainspaceChecklist />;
        sandbox = <div><a className="button dark small" href="https://en.wikipedia.org/wiki/Special:MyPage/sandbox" target="_blank">Sandbox</a></div>;
        sandboxTalk = <div><a className="button dark small" href="https://en.wikipedia.org/wiki/Special:MyTalk/sandbox" target="_blank">Sandbox talk</a></div>;
      }
    // Assigned articel that already exists
    } else if (this.props.assignment.role === 0) {
      if (isEnglishWikipedia) {
        checklist = <FinalArticleChecklist />;
      }
      assignmentType = 'Improving: ';
    // Review assignment
    } else {
      checklist = <PeerReviewChecklist />;
      assignmentType = 'Reviewing: ';
    }

    let divider;
    if (!this.props.last) {
      divider = <hr className="assignment-divider" />;
    }
    return (
      <div className="my-assignment">
        {assignmentType}<a className="my-assignment-title" href={this.props.assignment.article_url}>{this.props.assignment.article_title}</a>
        <div className="my-assignment-button">
          {feedback}
          {pageviews}
          {checklist}
          {sandboxTalk}
          {sandbox}
        </div>
        {divider}
      </div>
    );
  }
});

export default MyAssignment;
