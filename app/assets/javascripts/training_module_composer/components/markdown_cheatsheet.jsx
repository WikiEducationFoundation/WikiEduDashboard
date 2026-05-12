/* eslint-disable i18next/no-literal-string */
import React from 'react';

const ITEMS = [
  {
    label: 'Bold',
    syntax: '**bold text**',
    rendered: <strong>bold text</strong>,
  },
  {
    label: 'Italic',
    syntax: '*italic text*',
    rendered: <em>italic text</em>,
  },
  {
    label: 'Bulleted list',
    syntax: '- first item\n- second item',
    rendered: (
      <ul>
        <li>first item</li>
        <li>second item</li>
      </ul>
    ),
  },
  {
    label: 'Numbered list',
    syntax: '1. first step\n2. second step',
    rendered: (
      <ol>
        <li>first step</li>
        <li>second step</li>
      </ol>
    ),
  },
  {
    label: 'Link',
    syntax: '[link text](https://example.org)',
    rendered: <a href="https://example.org" onClick={e => e.preventDefault()}>link text</a>,
    note: 'Internal links can use a relative path, e.g. [sandbox](/training/students/how-to-edit).',
  },
  {
    label: 'Inline code',
    syntax: '`{{fact}}`',
    rendered: <code>{'{{fact}}'}</code>,
    note: 'Useful for showing wikitext like templates or links without rendering them.',
  },
  {
    label: 'Blockquote',
    syntax: '> quoted text',
    rendered: <blockquote>quoted text</blockquote>,
  },
  {
    label: 'Subheading',
    syntax: '## Subheading',
    rendered: <strong style={{ fontSize: '1.1em' }}>Subheading</strong>,
    note: 'The slide title is already rendered as a heading, so subheadings are rarely needed.',
  },
];

export const MarkdownCheatsheetToggle = ({ isOpen, onToggle }) => (
  <button
    type="button"
    className="training_module_composer__cheatsheet__toggle"
    onClick={onToggle}
    aria-expanded={isOpen}
  >
    {isOpen ? 'hide cheatsheet' : 'cheatsheet'}
  </button>
);

export const MarkdownCheatsheetPanel = ({ onClose }) => (
  <div className="training_module_composer__cheatsheet__panel" role="region" aria-label="Markdown cheatsheet">
    <button
      type="button"
      className="training_module_composer__cheatsheet__close"
      onClick={onClose}
      aria-label="Close cheatsheet"
    >
      ×
    </button>
    <table className="training_module_composer__cheatsheet__table">
      <tbody>
        {ITEMS.map(item => (
          <tr key={item.label}>
            <th scope="row">{item.label}</th>
            <td><pre>{item.syntax}</pre></td>
            <td>{item.rendered}</td>
          </tr>
        ))}
      </tbody>
    </table>
    {ITEMS.some(item => item.note) && (
      <ul className="training_module_composer__cheatsheet__notes">
        {ITEMS.filter(item => item.note).map(item => (
          <li key={item.label}>
            <strong>{item.label}:</strong> {item.note}
          </li>
        ))}
      </ul>
    )}
    <p className="training_module_composer__cheatsheet__footer">
      Full reference: <a href="https://commonmark.org/help/" target="_blank" rel="noopener noreferrer">commonmark.org/help</a>
    </p>
  </div>
);
