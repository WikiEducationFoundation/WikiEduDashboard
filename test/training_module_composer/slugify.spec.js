import '../testHelper';
import { slugifyTitle } from '../../app/assets/javascripts/training_module_composer/utils/slugify.js';

describe('slugifyTitle', () => {
  test('lowercases and hyphenates a plain title', () => {
    expect(slugifyTitle('Introduction to Wikipedia')).toBe('introduction-to-wikipedia');
  });

  test('strips punctuation', () => {
    expect(slugifyTitle('Five Pillars: Quiz!')).toBe('five-pillars-quiz');
  });

  test('collapses runs of non-alphanumerics into a single hyphen', () => {
    expect(slugifyTitle('hello   world --- test')).toBe('hello-world-test');
  });

  test('trims leading and trailing hyphens', () => {
    expect(slugifyTitle('---edge case---')).toBe('edge-case');
  });

  test('removes accents', () => {
    expect(slugifyTitle('Café au lait')).toBe('cafe-au-lait');
  });

  test('returns empty string for empty or nullish input', () => {
    expect(slugifyTitle('')).toBe('');
    expect(slugifyTitle(null)).toBe('');
    expect(slugifyTitle(undefined)).toBe('');
  });

  test('handles numbers alongside letters', () => {
    expect(slugifyTitle('Part 2: Details')).toBe('part-2-details');
  });
});
