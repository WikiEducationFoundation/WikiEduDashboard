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
  tab. Each article screenshot links to the article at the revision whose text
  matches it (a permalink, since articles keep changing — the Bicycle Tree
  sentence was reworded the day after this was written, and the RSP article's
  claim was reverted). The sources are linked inline from each case's
  concluding sentence, where the copy names them.
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
    {(children || link) && (
      <figcaption>
        {children}
        {link && (
          <a className="cv-example__link" href={link} target="_blank" rel="noopener noreferrer">
            {linkLabel}
          </a>
        )}
      </figcaption>
    )}
  </figure>
);

Figure.propTypes = {
  file: PropTypes.string.isRequired,
  alt: PropTypes.string.isRequired,
  // The article permalink the screenshot was taken from, if it has one.
  link: PropTypes.string,
  linkLabel: PropTypes.string,
  children: PropTypes.node,
};

// The article link reuses the taken-claim card's label for the same thing.
const articleLabel = () => I18n.t('claim_verification.find_in_article');

// A case's concluding sentence, with the source it names linked inline: the
// `_html` copy carries a %{source_link} slot, filled with the link text the
// copy also provides.
const conclusionHtml = (key, href) => I18n.t(
  `claim_verification.form.verification_example.${key}_conclusion_html`,
  {
    source_link: `<a href="${href}" target="_blank" rel="noopener noreferrer">${
      I18n.t(`claim_verification.form.verification_example.${key}_source_link_text`)
    }</a>`,
  }
);

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
        <Figure file="verified_example_source.webp" alt={t('verified_source_alt')} />
      </div>
      <p
        className="cv-example__conclusion"
        dangerouslySetInnerHTML={{ __html: conclusionHtml('verified', LINKS.verifiedSource) }}
      />
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
        <Figure file="failed_example_source.webp" alt={t('failed_source_alt')} />
      </div>
      <p
        className="cv-example__conclusion"
        dangerouslySetInnerHTML={{ __html: conclusionHtml('failed', LINKS.failedSource) }}
      />
    </section>
  </div>
);

export default VerificationExample;
