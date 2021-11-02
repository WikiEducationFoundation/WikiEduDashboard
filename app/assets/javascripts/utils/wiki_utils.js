const url = (wiki) => {
  const subdomain = wiki.language || 'www';
  return `${subdomain}.${wiki.project}.org`;
};

const formatOption = (wiki) => {
  return {
    value: JSON.stringify(wiki),
    label: url(wiki)
  };
};

export { formatOption };
