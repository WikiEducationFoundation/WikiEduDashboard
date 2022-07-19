const toWikiDomain = (wiki) => {
  const subdomain = wiki.language || 'www';
  return `${subdomain}.${wiki.project}.org`;
};

const formatOption = (wiki) => {
  return {
    value: JSON.stringify(wiki),
    label: toWikiDomain(wiki)
  };
};

const trackedWikisMaker = (course) => {
  let trackedWikis = [];
  if (course.wikis) {
    trackedWikis = course.wikis.map((wiki) => {
      wiki.language = wiki.language || 'www'; // for multilingual wikis language is null
      return formatOption(wiki);
    });
  }
  return trackedWikis;
};
export { trackedWikisMaker, formatOption, toWikiDomain };
