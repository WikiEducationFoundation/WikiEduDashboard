import '../testHelper';
import { inferDefaultCampaign } from '../../app/assets/javascripts/components/course/utils/inferDefaultCampaign';

const campaigns = [
  { id: 1, title: 'Spring 2022', slug: 'spring_2022' },
  { id: 2, title: 'Summer 2022', slug: 'summer_2022' },
  { id: 3, title: 'Fall 2022', slug: 'fall_2022' }
];
let start_date;

describe('No matching campaign', () => {
  test('returns null', () => {
    start_date = new Date(2019, 2, 5);
    const result = inferDefaultCampaign(campaigns, start_date);
    expect(result).toBe(null);
  });
});

describe('Matching campaigns available', () => {
  describe('December to April', () => {
    test('December 2021 - should return Spring 2022', () => {
      start_date = new Date(2021, 11, 1);
      const result = inferDefaultCampaign(campaigns, start_date);
      expect(result).toStrictEqual({ id: 1, title: 'Spring 2022', slug: 'spring_2022' });
    });

    test('April 2022 - should return Spring 2022', () => {
      start_date = new Date(2022, 3, 30);
      const result = inferDefaultCampaign(campaigns, start_date);
      expect(result).toStrictEqual({ id: 1, title: 'Spring 2022', slug: 'spring_2022' });
    });
  });

  describe('May to July', () => {
    test('May 2022 - should return Summer 2022', () => {
      start_date = new Date(2022, 4, 1);
      const result = inferDefaultCampaign(campaigns, start_date);
      expect(result).toStrictEqual({ id: 2, title: 'Summer 2022', slug: 'summer_2022' });
    });

    test('July 2022 - should return Summer 2022', () => {
      start_date = new Date(2022, 6, 31);
      const result = inferDefaultCampaign(campaigns, start_date);
      expect(result).toStrictEqual({ id: 2, title: 'Summer 2022', slug: 'summer_2022' });
    });
  });

  describe('August to November', () => {
    test('August 2022 - should return Fall 2022', () => {
      start_date = new Date(2022, 7, 1);
      const result = inferDefaultCampaign(campaigns, start_date);
      expect(result).toStrictEqual({ id: 3, title: 'Fall 2022', slug: 'fall_2022' });
    });

    test('November 2022 - should return Fall 2022', () => {
      start_date = new Date(2022, 10, 30);
      const result = inferDefaultCampaign(campaigns, start_date);
      expect(result).toStrictEqual({ id: 3, title: 'Fall 2022', slug: 'fall_2022' });
    });
  });
});
