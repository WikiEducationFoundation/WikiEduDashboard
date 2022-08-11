import React, { useState, useEffect } from 'react';
import { map } from 'lodash-es';
import Select from 'react-select';

import { wikiNamespaceLabel } from '../../utils/wiki_utils';

const projects_namespaces_ids = JSON.parse(ProjectNamespaces);

const NamespaceSelect = (props) => {
  const [selectedNamespaces, setSelectedNamespaces] = useState([]);
  const [options, setOptions] = useState([]);

  useEffect(() => {
    const selected = props.namespaces.map((wiki_ns) => {
      const wiki = wiki_ns.split('-')[0];
      const namespace = wiki_ns.split('-')[2];
      const label = wikiNamespaceLabel(wiki, namespace);
      const value = wiki_ns;
      return { label, value };
    });
    setSelectedNamespaces(selected);
  }, [props.namespaces]);

  useEffect(() => {
    updateNamespacesFromWikis();
    updateOptionsFromWikis();
  }, [props.wikis]);

  const updateNamespacesFromWikis = () => {
    const tracked_wikis = props.wikis;
    const tracked_namespaces = props.namespaces;

    const new_namespaces = tracked_wikis.map((wiki) => {
      const language = wiki.language || 'www'; // for multilingual wikis, language is null
      const project = wiki.project;
      const domain = `${language}.${project}.org`;
      return tracked_namespaces.filter((wiki_ns) => {
        return wiki_ns.split('-')[0] === domain;
      });
    }).reduce((a, b) => a.concat(b));
  updateNamespaces(new_namespaces);
  };

  const updateOptionsFromWikis = () => {
    const tracked_wikis = props.wikis;
    const new_options = tracked_wikis.map((wiki) => {
      const language = wiki.language || 'www';
      const project = wiki.project;
      const domain = `${language}.${project}.org`
      return projects_namespaces_ids[project].map((ns) => {
        const label = wikiNamespaceLabel(domain, ns);
        console.log('label - ', ns);
        const value = `${domain}-namespace-${ns}`;
        return { label, value };
      });
    }).reduce((a, b) => a.concat(b));
    return setOptions(new_options);
  };

  const handleChange = (selectedOptions) => {
    const tracked_namespaces = selectedOptions.map((option) => {
      return option.value;
    })
    updateNamespaces(tracked_namespaces);
  };

  const updateNamespaces = (namespaces) => {
    props.onChange(namespaces);
  };

  if (props.readOnly) {
    const lastIndex = props.namespaces.length - 1;

    const namespaceList = map(props.namespaces, (wiki_ns, index) => {
      const comma = (index !== lastIndex) ? ', ' : '';
      const wiki = wiki_ns.split('-')[0];
      const ns = wiki_ns.split('-')[2];
      const label = wikiNamespaceLabel(wiki, ns);
      return <span key={wiki_ns}>{label}{comma}</span>;
    });
    return (
      <>
        {namespaceList}
      </>
    );
  }

  return (
    <div>
      <Select
        id = "namespace_select"
        value = {selectedNamespaces}
        onChange = {handleChange}
        options = {options}
        styles={props.styles}
        isMulti = {true}
        isClearable={false}
      />
    </div>
  );
};

export default NamespaceSelect;
