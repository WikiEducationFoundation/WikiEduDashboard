import React from 'react';
import PropTypes from 'prop-types';

// components
import BibliographyLink from './BibliographyLink';
import SandboxLink from './SandboxLink';
import PeerReviewLink from './PeerReviewLink';
import EditorLink from './EditorLink';
import ReviewerLink from './ReviewerLink';

import Separator from '@components/overview/my_articles/common/Separator.jsx';

// constants
import { REVIEWING_ROLE } from '~/app/assets/javascripts/constants/assignments';

// helper functions
const interleaveSeparators = (acc, link, index, collection) => {
  const limit = collection.length - 1;
  const prefix = [...acc, link];

  return index < limit ? prefix.concat(<Separator key={index} />) : prefix;
};

export const Links = ({ articleTitle, assignment, courseType, current_user }) => {
  const { article_url, editors, id, reviewers } = assignment;
  let actions = [];

  if (courseType === 'ClassroomProgramCourse') {
    actions.push(
      <BibliographyLink key={`bibliography-${id}`} assignment={assignment} />
    );
  }

  actions.push(
    <SandboxLink key={`sandbox-${id}`} assignment={assignment} />
  );

  if (assignment.role === REVIEWING_ROLE) {
    actions.push(
      <PeerReviewLink key={`review-${id}`} assignment={assignment} current_user={current_user} />
    );
  }

  const article = (
    <a key={`article-${id}`} href={article_url} target="_blank">{I18n.t('assignments.article_link')}</a>
  );

  actions = actions.concat(article).reduce(interleaveSeparators, []);

  const assignedTo = (editors || reviewers)
    ? (
      <>
        <EditorLink key={`editor-${id}`} editors={editors} />
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
