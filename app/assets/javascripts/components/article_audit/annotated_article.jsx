import React, { useCallback, useEffect, useLayoutEffect, useMemo, useReducer, useRef, useState } from 'react';
import CommentCard from './comment_card.jsx';
import { layoutComments } from './comment_layout';

const t = (key, options) => I18n.t(`article_audit.${key}`, options);

const SEVERITY_ORDER = ['must_fix', 'should_fix', 'suggestion', 'info'];
const ACTIVE = 'aa-active';
// How far below the top of the window to put a highlight that a card
// scrolls to.
const SCROLL_MARGIN = 150;

const bySeverity = (a, b) => SEVERITY_ORDER.indexOf(a.severity) - SEVERITY_ORDER.indexOf(b.severity);

// The article as rendered, with each finding highlighted where it applies,
// and the findings beside it as comments level with their highlights (see
// comment_layout.js). Findings with no place in the text (anchor null) are
// listed at the top of the comment column. Selecting a highlight selects its
// comment, and selecting a comment scrolls to its highlight.
//
// The highlights come from the server (ArticleAuditing::FindingAnchors) as
// <mark data-findings="ids"> elements, and headings with
// data-section-findings for findings anchored to a section.
const AnnotatedArticle = ({ html, findings, hiddenSeverities }) => {
  const articleRef = useRef(null);
  const listRef = useRef(null);
  const cardRefs = useRef({});
  const [selectedId, setSelectedId] = useState(null);
  // { tops: { id: top }, height } for the anchored cards.
  const [layout, setLayout] = useState({ tops: {}, height: 0 });
  const { tops } = layout;
  // Bumped when the article or the window changes size, eg as images load.
  const [, onResize] = useReducer(count => count + 1, 0);

  const visible = useMemo(
    () => findings.filter(finding => !hiddenSeverities.includes(finding.severity)),
    [findings, hiddenSeverities]
  );
  const general = visible.filter(finding => !finding.anchor).sort(bySeverity);
  // In order down the article, which is also the order they're tabbed through.
  const anchored = visible.filter(finding => finding.anchor)
    .sort((a, b) => (tops[a.id] ?? 0) - (tops[b.id] ?? 0));

  const anchorElements = useCallback(id => (
    articleRef.current
      ? [...articleRef.current.querySelectorAll(`[data-findings~="${id}"], [data-section-findings~="${id}"]`)]
      : []
  ), []);

  useLayoutEffect(() => {
    if (!articleRef.current || !listRef.current) return;
    // Positions are relative to the list of anchored cards, which starts
    // below the whole-article findings.
    const base = listRef.current.getBoundingClientRect().top;
    const cards = anchored.flatMap(({ id }) => {
      const [anchor] = anchorElements(id);
      const card = cardRefs.current[id];
      return anchor && card ? [{ id, anchorTop: anchor.getBoundingClientRect().top - base, height: card.offsetHeight }] : [];
    });
    const nextTops = layoutComments(cards, { selectedId });
    const height = Math.max(0, ...cards.map(({ id, height: cardHeight }) => nextTops[id] + cardHeight));
    const next = { tops: nextTops, height };
    setLayout(previous => (JSON.stringify(previous) === JSON.stringify(next) ? previous : next));
  });

  useEffect(() => {
    const observer = new ResizeObserver(onResize);
    if (articleRef.current) observer.observe(articleRef.current);
    window.addEventListener('resize', onResize);
    return () => {
      observer.disconnect();
      window.removeEventListener('resize', onResize);
    };
  }, []);

  // Marks the selected finding's highlights. The article HTML is replaced
  // whenever the findings change, so this runs again then too.
  useEffect(() => {
    const article = articleRef.current;
    if (!article) return;
    article.querySelectorAll(`.${ACTIVE}`).forEach(element => element.classList.remove(ACTIVE));
    if (selectedId) anchorElements(selectedId).forEach(element => element.classList.add(ACTIVE));
  }, [selectedId, html, anchorElements]);

  const visibleIds = new Set(visible.map(finding => finding.id));

  // Clicking a highlight selects its finding; clicking again moves on to the
  // next finding on the same text.
  const onArticleClick = (event) => {
    if (event.target.closest('a')) return;
    const element = event.target.closest('[data-findings], [data-section-findings]');
    if (!element) return;
    const ids = (element.dataset.findings || element.dataset.sectionFindings).split(' ').filter(id => visibleIds.has(id));
    if (ids.length === 0) return;
    setSelectedId(ids[(ids.indexOf(selectedId) + 1) % ids.length]);
  };

  const selectCard = (id) => {
    if (id === selectedId) {
      setSelectedId(null);
      return;
    }
    setSelectedId(id);
    const [anchor] = anchorElements(id);
    if (anchor) {
      window.scrollTo({ top: anchor.getBoundingClientRect().top + window.scrollY - SCROLL_MARGIN, behavior: 'smooth' });
    }
  };

  const hiddenClasses = hiddenSeverities.map(severity => `aa-hide-${severity}`).join(' ');

  const card = finding => (
    <CommentCard
      key={finding.id}
      finding={finding}
      selected={finding.id === selectedId}
      onSelect={selectCard}
      top={finding.anchor ? tops[finding.id] : undefined}
      cardRef={(element) => { cardRefs.current[finding.id] = element; }}
    />
  );

  return (
    <div className={`article-audit-annotated ${html ? '' : 'article-audit-annotated--no-article'}`}>
      {html && (
        // Keyboard users select findings from the comment column, whose cards
        // are buttons; clicking a highlight is a shortcut to the same thing.
        // eslint-disable-next-line jsx-a11y/no-static-element-interactions, jsx-a11y/click-events-have-key-events
        <div
          ref={articleRef}
          className={`parsed-article article-audit-annotated__article ${hiddenClasses}`}
          onClick={onArticleClick}
          dangerouslySetInnerHTML={{ __html: html }}
        />
      )}
      <div className="article-audit-annotated__comments">
        {general.length > 0 && (
          <section className="article-audit-annotated__general">
            <h2>{t('whole_article')}</h2>
            <ul className="article-audit-annotated__list">{general.map(card)}</ul>
          </section>
        )}
        <ul ref={listRef} className="article-audit-annotated__list article-audit-annotated__list--anchored" style={{ height: layout.height }}>
          {anchored.map(card)}
        </ul>
      </div>
    </div>
  );
};

export default AnnotatedArticle;
