import '../testHelper';
import { extractSalesforceId } from '../../app/assets/javascripts/utils/salesforce_utils.js';

describe('extractSalesforceId', () => {
  test('extracts the ID from an old Salesforce URL', () => {
    const input = 'https://cs54.salesforce.com/c1f1f010013YOsu?srPos=2&srKp=a0f';
    const output = extractSalesforceId(input);
    expect(output).toBe('c1f1f010013YOsu');
  });
  test('works for new non-lightning URLs', () => {
    const input = 'https://wikied.my.salesforce.com/a0f1a000003yGxg';
    const output = extractSalesforceId(input);
    expect(output).toBe('a0f1a000003yGxg');
  });
  test('extracts the ID from a new Salesforce URL', () => {
    const input = 'https://wikied.lightning.force.com/one/one.app#/sObject/a0f1a000003yDoIAAU/view';
    const output = extractSalesforceId(input);
    expect(output).toBe('a0f1a000003yDoIAAU');
  });
  test('passes along an already-extracted ID', () => {
    const input = 'c1f1f010013YOsu';
    const output = extractSalesforceId(input);
    expect(output).toBe(input);
  });
});
