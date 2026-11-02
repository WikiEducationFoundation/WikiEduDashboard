import React from 'react';
import PropTypes from 'prop-types';

/*
  A claim and the source it cites, as the student reads them on the taken-claim
  view: the claim with a link to it in its article and the paragraph around it,
  then the citation with the button that opens the source. Shared by that view,
  the instructor's response cards and the students-tab response popover, so an
  instructor checking a student's answers sees the same claim and source the
  student was working from — the citation in particular, which the first
  questions are answered from alone.

  `headingLevel` places the two section labels under whatever heading the
  surroundings already have. The claim and source values are data.
*/
export const ClaimAndSource = ({ claim, headingLevel = 2 }) => {
  const Heading = `h${headingLevel}`;

  return (
    <>
      <section className="claim-verification-exercise__claim">
        <Heading className="claim-verification-exercise__label">{I18n.t('claim_verification.claim')}</Heading>
        <blockquote className="claim-verification-exercise__claim-text">{claim.sentence}</blockquote>
        {claim.article_url && (
          <p className="claim-verification-exercise__article-link">
            <a href={claim.article_url} target="_blank" rel="noopener noreferrer">
              {I18n.t('claim_verification.find_in_article')}
            </a>
          </p>
        )}
        {claim.context && (
          <details className="claim-verification-exercise__context">
            <summary>{I18n.t('claim_verification.show_surrounding')}</summary>
            <p>{claim.context}</p>
          </details>
        )}
      </section>

      <section className="claim-verification-exercise__source">
        <Heading className="claim-verification-exercise__label">{I18n.t('claim_verification.cited_source')}</Heading>
        {claim.cite_text && <p className="claim-verification-exercise__citation">{claim.cite_text}</p>}
        {claim.source_url ? (
          <a
            href={claim.source_url}
            className="button dark claim-verification-exercise__source-link"
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t('claim_verification.source_url')}
          </a>
        ) : (
          <p className="claim-verification-exercise__no-source">
            {I18n.t('claim_verification.no_online_source')}
          </p>
        )}
      </section>
    </>
  );
};

ClaimAndSource.propTypes = {
  claim: PropTypes.shape({
    sentence: PropTypes.string.isRequired,
    context: PropTypes.string,
    cite_text: PropTypes.string,
    source_url: PropTypes.string,
    article_url: PropTypes.string,
  }).isRequired,
  headingLevel: PropTypes.oneOf([2, 3, 4, 5]),
};

export default ClaimAndSource;
