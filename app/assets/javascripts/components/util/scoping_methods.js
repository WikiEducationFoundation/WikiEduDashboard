import { stringify } from 'query-string';
import { CATEGORIES, PAGEPILE, PETSCAN, TEMPLATES } from '../../constants/scoping_methods';

export const allScopingMethods = [
  CATEGORIES,
  PAGEPILE,
  PETSCAN,
  TEMPLATES,
];

export const getScopingMethodLabel = (method) => {
  switch (method) {
    case CATEGORIES:
      return I18n.t('courses_generic.creator.scoping_methods.categories');
    case TEMPLATES:
      return I18n.t('courses_generic.creator.scoping_methods.templates');
    case PAGEPILE:
      return I18n.t('courses_generic.creator.scoping_methods.pagepile');
    case PETSCAN:
      return I18n.t('courses_generic.creator.scoping_methods.petscan');
    case 'index':
      return I18n.t('courses_generic.creator.scoping_methods.configure');
    default:
      return '';
  }
};

export const getShortDescription = (method) => {
  switch (method) {
    case CATEGORIES:
      return I18n.t('courses_generic.creator.scoping_methods.categories_short_desc');
    case TEMPLATES:
      return I18n.t('courses_generic.creator.scoping_methods.templates_short_desc');
    case PAGEPILE:
      return I18n.t('courses_generic.creator.scoping_methods.pagepile_short_desc');
    case PETSCAN:
      return I18n.t('courses_generic.creator.scoping_methods.petscan_short_desc');
    default:
      return '';
  }
};

export const getLongDescription = (method) => {
  switch (method) {
    case CATEGORIES:
      return I18n.t('courses_generic.creator.scoping_methods.categories_desc');
    case TEMPLATES:
      return I18n.t('courses_generic.creator.scoping_methods.templates_desc');
    case PAGEPILE:
      return I18n.t('courses_generic.creator.scoping_methods.pagepile_desc');
    case PETSCAN:
      return I18n.t('courses_generic.creator.scoping_methods.petscan_desc');
    case 'index':
      return I18n.t('courses_generic.creator.scoping_methods.about');
    default:
      return '';
  }
};

export const generatePetScanUrl = ({ templates_includes, templates_excludes, categories_includes, categories_excludes }) => {
  const baseUrl = 'https://petscan.wmflabs.org/?';
  const params = {
    templates_any: templates_includes.map(x => x.label).join('\n'),
    templates_no: templates_excludes.map(x => x.label).join('\n'),
    categories: categories_includes.map(x => x.label).join('\n'),
    negcats: categories_excludes.map(x => x.label).join('\n'),
    doit: false,
    'ns[0]': true,
    format: 'html',
  };

  return `${baseUrl}?${stringify(params)}`;
};

export const generatePetScanID = async ({ templates_includes, templates_excludes, categories_includes, categories_excludes }) => {
  const request_url = generatePetScanUrl({ templates_includes, templates_excludes, categories_includes, categories_excludes });
  const response = await fetch(request_url);

  const html = await response.text();

  const parser = new DOMParser();
  const doc = parser.parseFromString(html, 'text/html');
  return doc.querySelector('span[name="psid"]').textContent;
};
