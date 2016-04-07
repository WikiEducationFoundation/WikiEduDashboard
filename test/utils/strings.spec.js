import '../testHelper';
import { capitalize, trunc } from '../../app/assets/javascripts/utils/strings';

describe('strings', () => {
  describe('truncate', () => {
    it('shortens a string to 15 characters plus ellipsis', () => {
      const testString = 'áBcdèfghijklmnopqrstuvwxyz';
      const truncatedString = trunc(testString);
      expect(truncatedString).to.eq('áBcdèfghijklmno…');
    });

    it('returns a string (not a string object) if it is less than truncation limit', () => {
      const testString = 'hello';
      const truncatedString = trunc(testString);
      expect(truncatedString).to.eq('hello');
      expect(typeof truncatedString).to.eq('string');
    });
  });

  describe('capitalize', () => {
    it('upcases the first constter of a string', () => {
      const testString = 'abCDE fg';
      const capitalizedString = capitalize(testString);
      expect(capitalizedString).to.eq('AbCDE fg');
    });

    it('handles unicode properly', () => {
      const testString = 'ábCDEfg';
      const capitalizedString = capitalize(testString);
      expect(capitalizedString).to.eq('ÁbCDEfg');
    });
  });
});
