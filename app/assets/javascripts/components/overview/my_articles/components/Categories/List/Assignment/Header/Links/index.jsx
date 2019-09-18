import React from 'react';

// components
import BibliographyLink from './BibliographyLink';
import SandboxLink from './SandboxLink';
import EditorLink from './EditorLink';
import ReviewerLink from '../../../../../../common/ReviewerLink';

import Separator from '../../../../../../common/Separator';

// constants
import { REVIEWING_ROLE } from '../../../../../../../../../constants/assignments';

export default ({ articleTitle, assignment, current_user }) => {
  const { article_url, editors, id, reviewers, sandboxUrl } = assignment;
  const { username } = current_user;

  let actions = [
    <BibliographyLink key={`bibliography-${id}`} assignment={assignment} />,
    <SandboxLink key={`sandbox-${id}`} assignment={assignment} />
  ];

  if (assignment.role === REVIEWING_ROLE) {
    let peerReviewUrl = `${sandboxUrl}/${username}_Peer_Review`;
    peerReviewUrl += '?veaction=edit&preload=Template:Dashboard.wikiedu.org_peer_review';
    actions.push(
      <a key={`review-${id}`} href={peerReviewUrl} target="_blank">{I18n.t('assignments.peer_review_link')}</a>
    );
  }

  const article = (
    <a key={`article-${id}`} href={article_url} target="_blank">{I18n.t('assignments.article_link')}</a>
  );

  actions = actions.concat(article).reduce((acc, link, index, collection) => {
    const limit = collection.length - 1;
    const prefix = [...acc, link];

    return index < limit ? prefix.concat(<Separator key={index} />) : prefix;
  }, []);

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
