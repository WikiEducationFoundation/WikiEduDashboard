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

  The screenshots are static assets; each links to itself full-size in a new
  tab. Under each, a link to what it shows: the article at the revision whose
  text matches the screenshot (a permalink, since articles keep changing — the
  Bicycle Tree sentence was reworded the day after this was written, and the
  RSP article's claim was reverted), and the cited source itself.
*/
const IMAGES = '/assets/images/claim_verification';

// The article revisions in the screenshots, and the sources they cite. The
// JSTOR article is paywalled for many students, but the link still shows them
// where the source lives.
const LINKS = {
  verifiedArticle: 'https://en.wikipedia.org/w/index.php?title=The_Bicycle_Tree&oldid=1368993077',
  verifiedSource: 'https://www.ocweekly.com/bicycle-tree-celebrates-a-decade-of-bike-activism-in-santana-7246869/',
  failedArticle: 'https://en.wikipedia.org/w/index.php?title=Revolutionary_Socialist_Party_(Zambia)&oldid=1328027773',
  failedSource: 'https://www.jstor.org/stable/3518767',
};

const Figure = ({ file, alt, link, linkLabel, children }) => (
  <figure className="cv-example__figure">
    <a href={`${IMAGES}/${file}`} target="_blank" rel="noopener noreferrer">
      <img src={`${IMAGES}/${file}`} alt={alt} loading="lazy" />
    </a>
    <figcaption>
      {children}
      <a className="cv-example__link" href={link} target="_blank" rel="noopener noreferrer">
        {linkLabel}
      </a>
    </figcaption>
  </figure>
);

Figure.propTypes = {
  file: PropTypes.string.isRequired,
  alt: PropTypes.string.isRequired,
  // Where the screenshot was taken: the article permalink or the source.
  link: PropTypes.string.isRequired,
  linkLabel: PropTypes.string.isRequired,
  children: PropTypes.node,
};

// The two links reuse the taken-claim card's own labels for the same things.
const articleLabel = () => I18n.t('claim_verification.find_in_article');
const sourceLabel = () => I18n.t('claim_verification.source_url');

const t = key => I18n.t(`claim_verification.form.verification_example.${key}`);

const VerificationExample = () => (
  <div className="cv-example">
    <p className="cv-example__lead">{t('lead')}</p>

    <section className="cv-example__case">
      <h3 className="cv-example__case-heading">{t('verified_heading')}</h3>
      <div className="cv-example__figures">
        <Figure
          file="verified_example_article.webp"
          alt={t('verified_article_alt')}
          link={LINKS.verifiedArticle}
          linkLabel={articleLabel()}
        >
          <span className="cv-example__caption-line">{t('verified_claim')}</span>
          <span className="cv-example__caption-line">{t('verified_source')}</span>
        </Figure>
        <Figure
          file="verified_example_source.webp"
          alt={t('verified_source_alt')}
          link={LINKS.verifiedSource}
          linkLabel={sourceLabel()}
        />
      </div>
      <p className="cv-example__conclusion">{t('verified_conclusion')}</p>
    </section>

    <section className="cv-example__case">
      <h3 className="cv-example__case-heading">{t('failed_heading')}</h3>
      <div className="cv-example__figures">
        <Figure
          file="failed_example_article.webp"
          alt={t('failed_article_alt')}
          link={LINKS.failedArticle}
          linkLabel={articleLabel()}
        />
        <Figure
          file="failed_example_source.webp"
          alt={t('failed_source_alt')}
          link={LINKS.failedSource}
          linkLabel={sourceLabel()}
        />
      </div>
      <p className="cv-example__conclusion">{t('failed_conclusion')}</p>
    </section>
  </div>
);

export default VerificationExample;
