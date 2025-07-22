import '../testHelper';
import { capitalize, trunc } from '../../app/assets/javascripts/utils/strings';

describe('strings', () => {
  describe('truncate', () => {
    test('shortens a string to 15 characters plus ellipsis', () => {
      const testString = 'áBcdèfghijklmnopqrstuvwxyz';
      const truncatedString = trunc(testString);
      expect(truncatedString).toBe('áBcdèfghijklmno…');
    });

    test(
      'returns a string (not a string object) if it is less than truncation limit',
      () => {
        const testString = 'hello';
        const truncatedString = trunc(testString);
        expect(truncatedString).toBe('hello');
        expect(typeof truncatedString).toBe('string');
      }
    );
  });

  describe('capitalize', () => {
    test('upcases the first constter of a string', () => {
      const testString = 'abCDE fg';
      const capitalizedString = capitalize(testString);
      expect(capitalizedString).toBe('AbCDE fg');
    });

    test('handles unicode properly', () => {
      const testString = 'ábCDEfg';
      const capitalizedString = capitalize(testString);
      expect(capitalizedString).toBe('ÁbCDEfg');
    });
  });
});
