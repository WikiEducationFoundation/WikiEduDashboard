import React, { useState, useEffect } from 'react';
import ArticleUtils from '../../utils/article_utils.js';
import ArrayUtils from '../../utils/array_utils';

import Select from 'react-select';

const projects_namespaces_ids = JSON.parse(ProjectNamespaces);

const NamespaceSelect = (props) => {
  const [selectedNamespaces, setSelectedNamespaces] = useState([]);
  const [options, setOptions] = useState([]);

  useEffect(() => {
    const namespaces = props.namespaces;
    const selected = namespaces.map((obj) => {
      const wiki = obj.wiki;
      const language = wiki.language;
      const project = wiki.project;
      return obj.namespaces.map((ns) => {
        const ns_id = ns;
        const ns_title = namespaceTitle(ns_id, project);
        const value = JSON.stringify({ wiki, ns_id });
        const label = `${ns_title} (${language}.${project}.org)`;
        const isClearableValue = ns_id !== 0;
        return { label, value, isClearableValue };
      });
    }).reduce((a, b) => a.concat(b));
    setSelectedNamespaces(selected);
  }, [props.namespaces]);

  useEffect(() => {
    updateNamespacesFromWikis();
    const newOptions = optionsFromWikis();
    setOptions(newOptions);
  }, [props.wikis]);

  const namespaceTitle = (id, project) => {
    let title = ArticleUtils.NamespaceTitleFromId[id];
    if (typeof (title) !== 'string') title = title[project];
    return I18n.t(`namespace.${title}`);
  };

  const updateNamespacesFromWikis = () => {
    const tracked_wikis = props.wikis;
    const tracked_namespaces = props.namespaces;

    const new_namespaces = tracked_wikis.map((wiki) => {
      wiki.language = wiki.language || 'www'; // for multilingual wikis, language is null
      let namespaces = [0];
      const main_ns_id = 0;
      const ns_obj = tracked_namespaces.find((obj) => {
        return JSON.stringify(obj.wiki) === JSON.stringify(wiki);
      });
      if (ns_obj !== undefined && ns_obj !== null) {
        namespaces = ns_obj.namespaces;
        if (ArrayUtils.hasObject(namespaces, main_ns_id)) return { wiki, namespaces };
        namespaces.unshift(main_ns_id);
        return { wiki, namespaces };
      }
      return { wiki, namespaces };
    });
    updateNamespaces(new_namespaces);
  };

  const optionsFromWikis = () => {
    const tracked_wikis = props.wikis;
    const new_options = tracked_wikis.map((wiki) => {
      const language = wiki.language || 'www';
      const project = wiki.project;
      return projects_namespaces_ids[project].map((ns_id) => {
        const ns_title = namespaceTitle(ns_id, project);
        const label = `${ns_title} (${language}.${project}.org)`;
        const value = JSON.stringify({ wiki, ns_id });
        return { label, value };
      });
    }).reduce((a, b) => a.concat(b));
    return new_options;
  };

  const handleChange = (selectedOptions) => {
    const tracked_wikis = props.wikis;
    const tracked_namespaces = tracked_wikis.map((wiki) => {
      wiki.language = wiki.language || 'www';
      const namespaces = [];
      selectedOptions.forEach((opt) => {
        const value = JSON.parse(opt.value);
        if (JSON.stringify(value.wiki) === JSON.stringify(wiki)) {
          namespaces.push(value.ns_id);
        }
      });
      return { wiki, namespaces };
    });
    updateNamespaces(tracked_namespaces);
  };

  const updateNamespaces = (namespaces) => {
    props.onChange(namespaces);
  };

  if (props.readOnly) {
    const namespaceList = props.namespaces.map((obj) => {
      const wiki = obj.wiki;
      const project = wiki.project;
      const language = wiki.language;

      return obj.namespaces.map((ns) => {
        const ns_title = namespaceTitle(ns, project);
        const ns_wiki_title = `${ns_title}(${language}.${project}.org), `;
        return <span key={ns_wiki_title}>{ns_wiki_title}</span>;
      });
    }).reduce((a, b) => a.concat(b));
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
