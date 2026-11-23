import '../testHelper';
import { bytesToWords } from '../../app/assets/javascripts/utils/wordcount_utils';

describe('bytesToWords', () => {
  it('rounds down, like WordCount.from_characters on the server', () => {
    // 10 bytes / 5.175 = 1.93, which the server reports as 1 word.
    expect(bytesToWords(10, 5.175)).toBe(1);
    expect(bytesToWords(10_350, 5.175)).toBe(2000);
    expect(bytesToWords(0, 5.175)).toBe(0);
  });
});
