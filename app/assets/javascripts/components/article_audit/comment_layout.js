// Vertical positions for comment cards beside an article, the way a document
// editor lays out comments: each card sits level with its anchor in the text
// unless that would overlap the card above, in which case it moves down.
//
// The selected card goes exactly level with its anchor. Cards after it are
// pushed down as usual; cards before it are pushed up out of its way, above
// `minTop` if need be (the column clips them, as a document editor scrolls
// them out of view).
//
// `cards` are { id, anchorTop, height }, in any order. Returns { id: top }.
export const layoutComments = (cards, { selectedId = null, gap = 8, minTop = 0 } = {}) => {
  const sorted = [...cards].sort((a, b) => a.anchorTop - b.anchorTop);
  const tops = {};
  const selectedIndex = sorted.findIndex(card => card.id === selectedId);
  const pivot = selectedIndex === -1 ? 0 : selectedIndex;

  // From the selected card (or the first) downward.
  let nextFree = minTop;
  sorted.slice(pivot).forEach((card, offset) => {
    const top = offset === 0 && selectedIndex !== -1
      ? Math.max(card.anchorTop, minTop)
      : Math.max(card.anchorTop, nextFree);
    tops[card.id] = top;
    nextFree = top + card.height + gap;
  });

  // Cards above the selected one, upward from it.
  let ceiling = selectedIndex === -1 ? null : tops[sorted[pivot].id];
  sorted.slice(0, pivot).reverse().forEach((card) => {
    const top = Math.min(card.anchorTop, ceiling - gap - card.height);
    tops[card.id] = top;
    ceiling = top;
  });

  return tops;
};

export default layoutComments;
