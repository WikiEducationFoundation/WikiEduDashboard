import React from 'react';
import PropTypes from 'prop-types';

// Components
import BibliographyLink from './BibliographyLink';
import EditorLink from './EditorLink';
import SandboxLink from './SandboxLink';
import GroupMembersLink from './GroupMembersLink';
import PeerReviewLink from './PeerReviewLink';
import AllPeerReviewLinks from './AllPeerReviewLinks';
import Separator from '@components/overview/my_articles/common/Separator.jsx';
import ArticleUtils from '../../../utils/article_utils';

// constants
import { ASSIGNED_ROLE, REVIEWING_ROLE } from '~/app/assets/javascripts/constants/assignments';

// helper functions
const interleaveSeparators = (acc, link, index, collection) => {
  const limit = collection.length - 1;
  const prefix = [...acc, link];

  return index < limit ? prefix.concat(<Separator key={index} />) : prefix;
};

const AssignmentLinks = ({ assignment, courseType, user, course, project, editMode }) => {
  const { article_url, id, role, editors } = assignment;
  const actions = [];

  if ((editors && editors.length) || assignment.role === ASSIGNED_ROLE) {
    // Exclude sandbox link for 'no_sandboxes' courses for existing articles.
    // New articles will still use sandboxes for drafting in 'no_sandboxes' courses.
    if (!assignment.article_id || !course?.no_sandboxes) {
      actions.push(
        <SandboxLink key={`sandbox-${id}`} assignment={assignment} editMode={editMode} user={user} />
      );
    }
  }

  if (courseType === 'ClassroomProgramCourse') {
    actions.unshift(
      <BibliographyLink key={`bibliography-${id}`} assignment={assignment} />
    );

    if (role === REVIEWING_ROLE) {
      actions.push(
        <PeerReviewLink key={`review-${id}`} assignment={assignment} user={user} />
      );
    }
  }

  // Only show mainspace article link if the article already exists.
  if (assignment.article_id) {
    const articleLink = (
      <a key={`article-${id}`} href={article_url} target="_blank">{I18n.t(`assignments.${ArticleUtils.projectSuffix(project, 'article_link')}`)}</a>
    );
    actions.push(articleLink);
  }

  let groupMembers;
  if (editors) {
    if (role === ASSIGNED_ROLE) {
      groupMembers = <GroupMembersLink members={editors} />;
    } else {
      groupMembers = <EditorLink key={`editor-${id}`} editors={editors} />;
    }
  }

  let reviewers;
  if (assignment.reviewers && role === ASSIGNED_ROLE) {
    reviewers = <AllPeerReviewLinks assignment={assignment} />;
  }

  // const reviewers = <ReviewerLink key={`reviewers-${id}`} reviewers={assignment.reviewers} />;
  const links = actions.reduce(interleaveSeparators, []);

  return (
    <section className="editors">
      <div className="assignment-links mb0">{ links }</div>
      {
        groupMembers && <p className="assignment-links mb0 editors">{groupMembers}</p>
      }
      {
        reviewers && <p className="assignment-links mb0 reviewers">{ reviewers }</p>
      }
    </section>
  );
};

AssignmentLinks.propTypes = {
  assignment: PropTypes.shape({
    id: PropTypes.number.isRequired,
    article_url: PropTypes.string,
    reviewers: PropTypes.array,
    role: PropTypes.number.isRequired
  }),
  project: PropTypes.string.isRequired,
  courseType: PropTypes.string.isRequired,
  user: PropTypes.object.isRequired
};

export default AssignmentLinks;
