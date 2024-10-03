import { getMonth, getYear } from 'date-fns';
import { toDate } from '~/app/assets/javascripts/utils/date_utils';

export const inferDefaultCampaign = (campaigns, course_start) => {
  // Try to infer the best suitable campaign from the start date of course.
  // Use the month and year to get the suitable term and compare it with the campaign slug.
  const month = getMonth(toDate(course_start));
  const year = getYear(toDate(course_start));

  let term;
  switch (month) {
    case 11:
      term = `spring_${year + 1}`;
      break;

    case 0: case 1: case 2: case 3:
      term = `spring_${year}`;
      break;

    case 4: case 5: case 6:
      term = `summer_${year}`;
      break;

    case 7: case 8: case 9: case 10:
      term = `fall_${year}`;
      break;

    default:
      term = '';
      break;
  }

  const defaultCampaign = campaigns.filter(campaign => campaign.slug === term);
  if (defaultCampaign.length > 0) {
    return defaultCampaign[0];
  }
  return null;
};
