import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { listDrafts, createDraft, deleteDraft } from '../api.js';

const DraftList = () => {
  const navigate = useNavigate();
  const [drafts, setDrafts] = useState(null);
  const [newName, setNewName] = useState('');
  const [error, setError] = useState(null);

  const refresh = () => listDrafts().then(data => setDrafts(data.drafts));

  useEffect(() => {
    refresh().catch(e => setError(e.message));
  }, []);

  const handleCreate = async (event) => {
    event.preventDefault();
    setError(null);
    try {
      const result = await createDraft({ name: newName });
      navigate(`/training_module_drafts/${result.draft.slug}`);
    } catch (e) {
      setError(e.message);
    }
  };

  const handleDelete = async (slug, name) => {
    if (!window.confirm(`Delete draft "${name || slug}"? This cannot be undone.`)) return;
    try {
      await deleteDraft(slug);
      refresh();
    } catch (e) {
      setError(e.message);
    }
  };

  if (drafts === null && !error) return <div>Loading…</div>;

  return (
    <div className="training_module_composer__list">
      <header>
        <h1>Training Module Composer</h1>
      </header>

      <section className="training_module_composer__new">
        <h2>Start a new draft</h2>
        <form onSubmit={handleCreate}>
          <label htmlFor="new_draft_name">Module name</label>
          <input
            id="new_draft_name"
            type="text"
            value={newName}
            onChange={e => setNewName(e.target.value)}
            placeholder="e.g. Working with citations"
            required
          />
          <button type="submit" className="button dark" disabled={!newName.trim()}>
            Create draft
          </button>
        </form>
      </section>

      {error && <div className="notification error">{error}</div>}

      <section className="training_module_composer__existing">
        <h2>Existing drafts</h2>
        {drafts && drafts.length === 0 && <p>No drafts yet.</p>}
        {drafts && drafts.length > 0 && (
          <table className="table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Slug</th>
                <th>Slides</th>
                <th>Module id</th>
                <th>Updated</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {drafts.map(draft => (
                <tr key={draft.slug}>
                  <td>
                    <a
                      href={`/training_module_drafts/${draft.slug}`}
                      onClick={(e) => {
                        e.preventDefault();
                        navigate(`/training_module_drafts/${draft.slug}`);
                      }}
                    >
                      {draft.name || draft.slug}
                    </a>
                  </td>
                  <td><code>{draft.slug}</code></td>
                  <td>{draft.slide_count}</td>
                  <td>{draft.module_id}</td>
                  <td>{new Date(draft.updated_at).toLocaleString()}</td>
                  <td>
                    <button
                      type="button"
                      className="button danger small"
                      onClick={() => handleDelete(draft.slug, draft.name)}
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
};

export default DraftList;
