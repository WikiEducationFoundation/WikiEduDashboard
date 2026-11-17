import { layoutComments } from './comment_layout';

describe('layoutComments', () => {
  const cards = [
    { id: 'a', anchorTop: 100, height: 50 },
    { id: 'b', anchorTop: 120, height: 50 },
    { id: 'c', anchorTop: 400, height: 50 }
  ];

  it('places cards level with their anchors when there is room', () => {
    const tops = layoutComments([{ id: 'a', anchorTop: 100, height: 50 }, { id: 'c', anchorTop: 400, height: 50 }]);
    expect(tops).toEqual({ a: 100, c: 400 });
  });

  it('pushes an overlapping card below the one above it', () => {
    expect(layoutComments(cards, { gap: 10 })).toEqual({ a: 100, b: 160, c: 400 });
  });

  it('puts the selected card level with its anchor and moves earlier cards up', () => {
    expect(layoutComments(cards, { selectedId: 'b', gap: 10 })).toEqual({ a: 60, b: 120, c: 400 });
  });

  it('starts unselected cards at minTop, but lets earlier cards go above it to make room for the selected one', () => {
    expect(layoutComments(cards, { minTop: 110, gap: 10 })).toEqual({ a: 110, b: 170, c: 400 });
    expect(layoutComments(cards, { selectedId: 'b', minTop: 90, gap: 10 })).toEqual({ a: 60, b: 120, c: 400 });
  });

  it('ignores the order cards are given in', () => {
    expect(layoutComments([...cards].reverse(), { gap: 10 })).toEqual({ a: 100, b: 160, c: 400 });
  });
});
