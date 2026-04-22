import React, { useState } from 'react';

const ModuleMetadataForm = ({ draft, onChange }) => {
  const [open, setOpen] = useState(false);

  return (
    <section className={`training_module_composer__metadata${open ? ' open' : ''}`}>
      <button
        type="button"
        className="training_module_composer__metadata__toggle"
        aria-expanded={open}
        onClick={() => setOpen(v => !v)}
      >
        <span className="training_module_composer__metadata__caret" aria-hidden="true">
          {open ? '▾' : '▸'}
        </span>
        <span className="training_module_composer__metadata__summary">
          Module details
          <small>
            {draft.name || 'Untitled'} · <code>{draft.slug}</code> · id {draft.module_id ?? '—'}
            {draft.estimated_ttc ? ` · ${draft.estimated_ttc}` : ''}
          </small>
        </span>
      </button>

      {open && (
        <div className="training_module_composer__metadata__fields">
          <div className="training_module_composer__field">
            <label htmlFor="module_name">Module name</label>
            <input
              id="module_name"
              type="text"
              value={draft.name || ''}
              onChange={e => onChange({ name: e.target.value })}
            />
          </div>

          <div className="training_module_composer__field">
            <label htmlFor="module_description">Description</label>
            <textarea
              id="module_description"
              rows={3}
              value={draft.description || ''}
              onChange={e => onChange({ description: e.target.value })}
            />
          </div>

          <div className="training_module_composer__field">
            <label htmlFor="module_estimated_ttc">Estimated time</label>
            <input
              id="module_estimated_ttc"
              type="text"
              placeholder="e.g. 15-25 minutes"
              value={draft.estimated_ttc || ''}
              onChange={e => onChange({ estimated_ttc: e.target.value })}
            />
          </div>

          <div className="training_module_composer__field">
            <label htmlFor="module_slug">Slug</label>
            <input
              id="module_slug"
              type="text"
              value={draft.slug || ''}
              onChange={e => onChange({ slug: e.target.value })}
              pattern="[a-z0-9][a-z0-9-]*"
              title="Lowercase letters, digits, and hyphens. Must start with a letter or digit."
            />
            <small>The draft file will be renamed to match on the next save.</small>
          </div>

          <div className="training_module_composer__field training_module_composer__readonly">
            <label>Module id</label>
            <code>{draft.module_id ?? '—'}</code>
            <small>Assigned automatically and can&apos;t be changed.</small>
          </div>
        </div>
      )}
    </section>
  );
};

export default ModuleMetadataForm;
