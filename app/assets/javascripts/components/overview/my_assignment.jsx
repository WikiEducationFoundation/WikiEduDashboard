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

// Helper Components
// Actions Components
const RemoveButton = ({ assignment, unassign }) => (
  <div>
    <button
      onClick={() => unassign(assignment)}
      className="button danger small"
    >
        Remove
    </button>
  </div>
);

const PageViews = ({ article }) => {
  const pageviewUrl = `https://tools.wmflabs.org/pageviews/?project=${article.language}.${article.project}.org&platform=all-access&agent=user&range=latest-90&pages=${article.title}`;
  return (
    <div>
      <a className="button dark small" href={pageviewUrl} target="_blank">Pageviews</a>
    </div>
  );
};

const Actions = ({
  article, assignment, current_user, username,
  isEnglishWikipedia, unassign
}) => {
  const actions = [];

  if (assignment.article_id) {
    actions.push(<PageViews key="pageviews-button" article={article} />);
  }

  // Assigned article that does not yet exist in mainspace
  if (isEnglishWikipedia()) {
    const feedback = (
      <Feedback
        assignment={assignment}
        current_user={current_user}
        key="feedback-button"
        username={username}
      />
    );
    if (assignment.role === 0 && !assignment.article_id) {
      actions.push(<MainspaceChecklist key="mainspace-button" />, feedback);
    } else if (assignment.role === 0) {
      actions.push(<FinalArticleChecklist key="final-article-button" />, feedback);
    } else {
      actions.push(<PeerReviewChecklist key="peer-review-button" />);
    }
  }

  return (
    <section className="actions">
      { actions }
      <RemoveButton key="remove-button" assignment={assignment} unassign={unassign} />
    </section>
  );
};

// Links Components
const BibliographyLink = ({ assignment }) => {
  const link = `${assignment.sandboxUrl}/bibliography`;
  return <a href={link}>{I18n.t('assignments.bibliography')}</a>;
};

const AssignedToLink = ({ name, members }) => {
  if (!members) return null;

  const label = <span key="label">{I18n.t(`assignments.${name}`)}: </span>;
  const links = members.map((username, index, collection) => {
    return (
      <span key={username}>
        <a href={`/users/${username}`}>
          {username}
        </a>
        {index < collection.length - 1 ? ', ' : null}
      </span>
    );
  });

  return [label].concat(links);
};

const EditorLink = ({ editors }) => {
  return <AssignedToLink members={editors} name="editors" />;
};

const ReviewerLink = ({ reviewers }) => {
  return <AssignedToLink members={reviewers} name="reviewers" />;
};

const Separator = () => <span> •&nbsp;</span>;

const Links = ({ articleTitle, assignment }) => {
  const { article_url, editors, id, reviewers, sandboxUrl } = assignment;
  const actions = [
    <BibliographyLink key={`bibliography-${id}`} assignment={assignment} />,
    <a key={`sandbox-${id}`} href={sandboxUrl} target="_blank">{I18n.t('assignments.sandbox_draft_link')}</a>,
    <a key={`article-${id}`} href={article_url}>{I18n.t('assignments.article_link')}</a>
  ].reduce((acc, link, index, collection) => {
    const limit = collection.length - 1;
    const prefix = [...acc, link];

    return index < limit ? prefix.concat(<Separator key={index} />) : prefix;
  }, []);

  const assignedTo = (editors || reviewers)
    ? (
      <>
        <EditorLink key={`editor-${id}`} editors={editors} />
        { (editors && reviewers) ? <Separator key="member-links" /> : null }
        <ReviewerLink key={`reviewer-${id}`} reviewers={reviewers} />
      </>
    )
    : null;
  return (
    <section className="header">
      <section className="title">
        <h4>{articleTitle}</h4>
      </section>
      <section className="editors">
        {assignedTo && <p className="mb0">{assignedTo}</p>}
        <p>{actions}</p>
      </section>
    </section>
  );
};

// Main Component
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
      this.props.deleteAssignment({ course_slug: this.props.course.slug, ...assignment });
    });
  },

  render() {
    const { assignment, course, current_user, username, wikidataLabels } = this.props;

    const article = CourseUtils.articleFromTitleInput(assignment.article_url);
    const label = wikidataLabels[article.title.replace('www:wikidata', '')];
    let articleTitle = assignment.article_title;
    articleTitle = CourseUtils.formattedArticleTitle(article, course.home_wiki, label);

    return (
      <div className="my-assignment mb1">
        <Links articleTitle={articleTitle} assignment={assignment} />
        <Actions
          article={article}
          assignment={assignment}
          current_user={current_user}
          username={username}
          isEnglishWikipedia={this.isEnglishWikipedia}
          unassign={this.unassign}
        />
      </div>
    );
  }
});

const mapDispatchToProps = {
  initiateConfirm,
  deleteAssignment
};

export default connect(null, mapDispatchToProps)(MyAssignment);
