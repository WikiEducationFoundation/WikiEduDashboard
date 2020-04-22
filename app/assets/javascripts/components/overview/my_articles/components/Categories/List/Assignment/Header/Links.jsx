import React from 'react';
import PropTypes from 'prop-types';

// components
import BibliographyLink from '@components/common/AssignmentLinks/BibliographyLink.jsx';
import SandboxLink from '@components/common/AssignmentLinks/SandboxLink.jsx';
import PeerReviewLink from '@components/common/AssignmentLinks/PeerReviewLink.jsx';
import EditorLink from '@components/common/AssignmentLinks/EditorLink.jsx';
import GroupMembersLink from '@components/common/AssignmentLinks/GroupMembersLink.jsx';
import ReviewerLink from '@components/common/AssignmentLinks/ReviewerLink.jsx';

import Separator from '@components/overview/my_articles/common/Separator.jsx';

// constants
import { ASSIGNED_ROLE, REVIEWING_ROLE } from '~/app/assets/javascripts/constants/assignments';

// helper functions
const interleaveSeparators = (acc, link, index, collection) => {
  const limit = collection.length - 1;
  const prefix = [...acc, link];

  return index < limit ? prefix.concat(<Separator key={index} />) : prefix;
};

export const Links = ({ articleTitle, assignment, courseType, current_user }) => {
  const { article_url, editors, id, reviewers } = assignment;
  let actions = [];

  if ((editors && editors.length) || assignment.role === ASSIGNED_ROLE) {
    actions.push(
      <SandboxLink key={`sandbox-${id}`} assignment={assignment} />
    );
  }

  if (courseType === 'ClassroomProgramCourse') {
    actions.unshift(
      <BibliographyLink key={`bibliography-${id}`} assignment={assignment} />
    );
    if (assignment.role === REVIEWING_ROLE) {
      actions.push(
        <PeerReviewLink key={`review-${id}`} assignment={assignment} user={current_user} />
      );
    }
  }

  const article = (
    <a key={`article-${id}`} href={article_url} target="_blank">{I18n.t('assignments.article_link')}</a>
  );

  actions = actions.concat(article).reduce(interleaveSeparators, []);

  const assignedTo = (editors || reviewers)
    ? (
      <>
        {
          assignment.role === REVIEWING_ROLE
            ? <EditorLink key={`editor-${id}`} editors={editors} />
            : <GroupMembersLink key={`editor-${id}`} members={editors} />
        }
        {(editors && reviewers) ? <Separator key="member-links" /> : null}
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

Links.propTypes = {
  // props
  articleTitle: PropTypes.string.isRequired,
  assignment: PropTypes.object.isRequired,
  courseType: PropTypes.string.isRequired,
  current_user: PropTypes.object.isRequired,
};

export default Links;
