import React from 'react';

const Row = ({ link, title }) => (
  <tr className="training-module">
    <td className="block__training-modules-table__module-name">{ title }</td>
    <td className="block__training-modules-table__module-link">
      <a href={link} target="_blank">
        Visit
        <i className="icon icon-rt_arrow_purple_training" />
      </a>
    </td>
  </tr>
);

export default () => {
  const rows = [
    { title: 'Bibliography Template', link: 'https://en.wikipedia.org/wiki/Template:Dashboard.wikiedu.org_bibliography' },
    { title: 'Evaluate an Article Template', link: 'https://en.wikipedia.org/wiki/Template:Dashboard.wikiedu.org_evaluate_article' },
    { title: 'Choose an Article Template', link: 'https://en.wikipedia.org/wiki/Template:Dashboard.wikiedu.org_choose_article' },
    { title: 'Article Draft Template', link: 'https://en.wikipedia.org/wiki/Template:Dashboard.wikiedu.org_draft_template' },
    { title: 'Peer Review Template', link: 'https://en.wikipedia.org/wiki/Template:Dashboard.wikiedu.org_peer_review' }
  ];

  return (
    <div className="list-unstyled container mt2 mb2">
      <h4>Templates</h4>
      <p>If you make changes to any of the sandbox userpages, you can always refer back to the templates below.</p>
      <table className="table table--small">
        <tbody>
          { rows.map((resource, i) => <Row key={`resource-${i}`} {...resource} />) }
        </tbody>
      </table>
    </div>
  );
};
