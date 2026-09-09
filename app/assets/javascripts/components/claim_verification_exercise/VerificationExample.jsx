import React from 'react';
import PropTypes from 'prop-types';

/*
  The worked example in the verify step of the fact-verification exercise: two
  cases, each a claim in its Wikipedia article next to the cited source. In the
  first the passage is found; in the second a search of the source comes up
  empty — so the student sees what "the source supports the claim" does and
  doesn't look like before giving their own verdict. Named as the
  `verification_example` illustration in config/claim_verification_exercise.yml;
  the copy is under claim_verification.form.verification_example.

  The screenshots are static assets. At half the card's width they are
  thumbnails, so each links to itself full-size in a new tab.
*/
const IMAGES = '/assets/images/claim_verification';

const Figure = ({ file, alt, children }) => (
  <figure className="cv-example__figure">
    <a href={`${IMAGES}/${file}`} target="_blank" rel="noopener noreferrer">
      <img src={`${IMAGES}/${file}`} alt={alt} loading="lazy" />
    </a>
    {children && <figcaption>{children}</figcaption>}
  </figure>
);

Figure.propTypes = {
  file: PropTypes.string.isRequired,
  alt: PropTypes.string.isRequired,
  children: PropTypes.node,
};

const t = key => I18n.t(`claim_verification.form.verification_example.${key}`);

const VerificationExample = () => (
  <div className="cv-example">
    <p className="cv-example__lead">{t('lead')}</p>

    <section className="cv-example__case">
      <h3 className="cv-example__case-heading">{t('verified_heading')}</h3>
      <div className="cv-example__figures">
        <Figure file="verified_example_article.webp" alt={t('verified_article_alt')}>
          <span className="cv-example__caption-line">{t('verified_claim')}</span>
          <span className="cv-example__caption-line">{t('verified_source')}</span>
        </Figure>
        <Figure file="verified_example_source.webp" alt={t('verified_source_alt')} />
      </div>
      <p className="cv-example__conclusion">{t('verified_conclusion')}</p>
    </section>

    <section className="cv-example__case">
      <h3 className="cv-example__case-heading">{t('failed_heading')}</h3>
      <div className="cv-example__figures">
        <Figure file="failed_example_article.webp" alt={t('failed_article_alt')} />
        <Figure file="failed_example_source.webp" alt={t('failed_source_alt')} />
      </div>
      <p className="cv-example__conclusion">{t('failed_conclusion')}</p>
    </section>
  </div>
);

export default VerificationExample;
