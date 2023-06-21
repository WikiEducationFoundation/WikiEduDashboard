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

export const generatePetScanUrl = ({ templates_includes, templates_excludes, categories_includes, categories_excludes, namespaces }, home_wiki) => {
  let { language, project } = home_wiki;
  if (language === 'www' && project === 'wikidata') {
    // special casing for wikidata
    // this is how PetScan expects it
    language = 'wikidata';
    project = 'wikimedia';
  }
  const baseUrl = 'https://petscan.wmflabs.org/?';
  const params = {
    templates_any: templates_includes.map(x => x.label).join('\n'),
    templates_no: templates_excludes.map(x => x.label).join('\n'),
    categories: categories_includes.map(x => x.label).join('\n'),
    negcats: categories_excludes.map(x => x.label).join('\n'),
    doit: false,
    language,
    project,
    ...includeNamespaces(namespaces),
    format: 'html',
  };

  return `${baseUrl}?${stringify(params)}`;
};

export const generatePetScanID = async ({ templates_includes, templates_excludes, categories_includes, categories_excludes, namespaces }, home_wiki) => {
  if (!templates_includes.length && !templates_excludes.length && !categories_includes.length && !categories_excludes.length) {
    return '';
  }
  const request_url = generatePetScanUrl({ templates_includes, templates_excludes, categories_includes, categories_excludes, namespaces }, home_wiki);
  const response = await fetch(request_url);

  const html = await response.text();

  const parser = new DOMParser();
  const doc = parser.parseFromString(html, 'text/html');
  return doc.querySelector('span[name="psid"]').textContent;
};


export const getScopingMethods = async (scopingMethods, home_wiki) => {
  const { selected } = scopingMethods;
  const result = {};

  // eslint-disable-next-line no-restricted-syntax
  for (const selectedItem of selected) {
    // only add the scoping method to the final object if it is selected
    result[selectedItem.toLowerCase()] = scopingMethods[selectedItem.toLowerCase()];
  }
  if (result.petscan) {
    try {
      const psid = await generatePetScanID(result.petscan, home_wiki);
      if (psid) {
        result.petscan.psids.push({
          label: psid,
          value: psid,
        });
      }
    } catch (e) {
      // eslint-disable-next-line no-console
      console.log(e);
    }
  }
  return result;
};

export const getAvailableNamespaces = () => {
  return [
    { label: 'Mainspace', value: '0' },
    { label: 'Talk', value: '1' },
    { label: 'User', value: '2' },
    { label: 'User talk', value: '3' },
    { label: 'Wikipedia', value: '4' },
    { label: 'Wikipedia talk', value: '5' },
    { label: 'File', value: '6' },
    { label: 'File talk', value: '7' },
    { label: 'MediaWiki', value: '8' },
    { label: 'MediaWiki talk', value: '9' },
    { label: 'Template', value: '10' },
    { label: 'Template talk', value: '11' },
    { label: 'Help', value: '12' },
    { label: 'Help talk', value: '13' },
    { label: 'Category', value: '14' },
    { label: 'Category talk', value: '15' },
    { label: 'Portal', value: '100' },
    { label: 'Portal talk', value: '101' },
    { label: 'Draft', value: '118' },
    { label: 'Draft talk', value: '119' },
    { label: 'TimedText', value: '710' },
    { label: 'TimedText talk', value: '711' },
    { label: 'Module', value: '828' },
    { label: 'Module talk', value: '829' },
    { label: 'Gadget', value: '2300' },
    { label: 'Gadget talk', value: '2301' },
    { label: 'Gadget definition', value: '2302' },
    { label: 'Gadget definition talk', value: '2303' },
  ];
};

export const includeNamespaces = (namespaces) => {
  const result = {};

  // eslint-disable-next-line no-restricted-syntax
  for (const namespace of namespaces) {
    result[`ns[${namespace.value}]`] = true;
  }
  return result;
};
