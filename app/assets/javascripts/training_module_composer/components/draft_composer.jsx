import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { getDraft, updateDraft, exportUrl, getExistingSlideSlugs } from '../api.js';
import ModuleMetadataForm from './module_metadata_form.jsx';
import SlideSidebar from './slide_sidebar.jsx';
import SlideEditor from './slide_editor.jsx';
import PasteImportModal from './paste_import_modal.jsx';
import DraftPreview from './draft_preview.jsx';
import { slugifyTitle } from '../utils/slugify.js';

const emptySlide = () => ({ slug: '', title: '', content: '' });

const DraftComposer = () => {
  const { slug } = useParams();
  const navigate = useNavigate();
  const [draft, setDraft] = useState(null);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [saving, setSaving] = useState(false);
  const [dirty, setDirty] = useState(false);
  const [error, setError] = useState(null);
  const [status, setStatus] = useState(null);
  const [pasteOpen, setPasteOpen] = useState(false);
  const [previewOpen, setPreviewOpen] = useState(false);
  const [sidebarEditMode, setSidebarEditMode] = useState(false);
  const [existingSlugs, setExistingSlugs] = useState(null);

  useEffect(() => {
    getDraft(slug)
      .then(data => setDraft(data.draft))
      .catch(e => setError(e.message));
  }, [slug]);

  useEffect(() => {
    getExistingSlideSlugs()
      .then(data => setExistingSlugs(new Set(data.slugs)))
      .catch(() => setExistingSlugs(new Set()));
  }, []);

  const updateMetadata = (changes) => {
    setDraft(current => ({ ...current, ...changes }));
    setDirty(true);
  };

  const updateSlide = (index, changes) => {
    setDraft((current) => {
      const slides = current.slides.map((s, i) => (i === index ? { ...s, ...changes } : s));
      return { ...current, slides };
    });
    setDirty(true);
  };

  const addSlide = () => {
    setDraft((current) => {
      const slides = [...current.slides, emptySlide()];
      setSelectedIndex(slides.length - 1);
      return { ...current, slides };
    });
    setDirty(true);
  };

  const deleteSlide = (index) => {
    setDraft((current) => {
      const slides = current.slides.filter((_, i) => i !== index);
      return { ...current, slides };
    });
    setSelectedIndex(prev => Math.max(0, Math.min(prev, (draft?.slides.length ?? 1) - 2)));
    setDirty(true);
  };

  const moveSlide = (from, to) => {
    if (from === to) return;
    setDraft((current) => {
      const slides = [...current.slides];
      const [moved] = slides.splice(from, 1);
      slides.splice(to, 0, moved);
      return { ...current, slides };
    });
    setSelectedIndex(to);
    setDirty(true);
  };

  const applyPastedSlides = (slides) => {
    setDraft(current => ({ ...current, slides }));
    setSelectedIndex(0);
    setPasteOpen(false);
    setDirty(true);
  };

  const save = async () => {
    if (!draft) return;
    setSaving(true);
    setError(null);
    setStatus(null);
    try {
      const result = await updateDraft(slug, {
        name: draft.name,
        description: draft.description,
        estimated_ttc: draft.estimated_ttc,
        slug: draft.slug,
        slides: draft.slides.map(s => ({
          slug: s.slug || slugifyTitle(s.title),
          title: s.title,
          content: s.content
        }))
      });
      setDraft(result.draft);
      setDirty(false);
      setStatus('Draft saved.');
      if (result.draft.slug && result.draft.slug !== slug) {
        navigate(`/training_module_drafts/${result.draft.slug}`, { replace: true });
      }
    } catch (e) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  };

  if (error && !draft) {
    return (
      <div className="training_module_composer__composer">
        <p><Link to="/training_module_drafts">← Back to drafts</Link></p>
        <div className="notification error">{error}</div>
      </div>
    );
  }
  if (!draft) return <div>Loading…</div>;

  const effectiveSlugs = draft.slides.map(s => (s.slug || slugifyTitle(s.title)));
  const duplicateSlugs = new Set();
  const seen = new Set();
  effectiveSlugs.forEach((s) => {
    if (!s) return;
    if (seen.has(s)) duplicateSlugs.add(s);
    seen.add(s);
  });
  const collisionForSlide = (index) => {
    const s = effectiveSlugs[index];
    if (!s) return null;
    if (existingSlugs && existingSlugs.has(s)) return 'existing';
    if (duplicateSlugs.has(s)) return 'duplicate';
    return null;
  };
  const collisionCount = draft.slides.filter((_, i) => collisionForSlide(i)).length;
  const missingModuleFields = [
    !draft.name ? 'name' : null,
    !draft.description ? 'description' : null
  ].filter(Boolean);
  const missingSlideCount = draft.slides.filter(s => !s.title || !s.content).length;

  const selectedSlide = draft.slides[selectedIndex];

  return (
    <div className="training_module_composer__composer">
      <header className="training_module_composer__header">
        <p><Link to="/training_module_drafts">← Back to drafts</Link></p>
        <h1>
          {draft.name || 'Untitled draft'}
          {dirty && <span className="training_module_composer__dirty"> (unsaved)</span>}
        </h1>
        <div className="training_module_composer__actions">
          <button type="button" className="button dark" onClick={save} disabled={saving || !dirty}>
            {saving ? 'Saving…' : 'Save draft'}
          </button>
          <button type="button" className="button" onClick={() => setPasteOpen(true)}>
            Paste content
          </button>
          <button
            type="button"
            className="button"
            onClick={() => setPreviewOpen(true)}
            disabled={!draft.slides.length}
          >
            Preview
          </button>
          <a className="button" href={exportUrl(slug)}>Export zip</a>
        </div>
      </header>

      {error && <div className="notification error">{error}</div>}
      {status && !error && <div className="notification success">{status}</div>}
      {collisionCount > 0 && (
        <div className="notification warning">
          {collisionCount === 1 ? '1 slide has a' : `${collisionCount} slides have a`} slug
          that clashes with an existing training slide or another slide in this draft.
          Resolve the collisions before importing the exported module, or the loader will
          raise a duplicate-key error.
        </div>
      )}
      {missingModuleFields.length > 0 && (
        <div className="notification warning">
          Missing module {missingModuleFields.join(' and ')}. Once imported, the training
          page will fail to render because Redcarpet can&apos;t render an empty description.
          Fill in the module details before exporting.
        </div>
      )}
      {missingSlideCount > 0 && (
        <div className="notification warning">
          {missingSlideCount === 1 ? '1 slide is' : `${missingSlideCount} slides are`} missing
          a title or content. Empty slides render as blank pages in the training UI.
        </div>
      )}

      <ModuleMetadataForm draft={draft} onChange={updateMetadata} />

      <div
        className={`training_module_composer__body${sidebarEditMode ? ' sidebar-edit' : ''}`}
      >
        <SlideSidebar
          slides={draft.slides}
          selectedIndex={selectedIndex}
          onSelect={setSelectedIndex}
          onAdd={addSlide}
          onDelete={deleteSlide}
          onMove={moveSlide}
          editMode={sidebarEditMode}
          onToggleEditMode={() => setSidebarEditMode(v => !v)}
          collisionForSlide={collisionForSlide}
        />
        {selectedSlide ? (
          <SlideEditor
            slide={selectedSlide}
            index={selectedIndex}
            moduleId={draft.module_id}
            onChange={changes => updateSlide(selectedIndex, changes)}
            collision={collisionForSlide(selectedIndex)}
          />
        ) : (
          <div className="training_module_composer__empty">
            <p>No slides yet. Add one to get started.</p>
            <button type="button" className="button" onClick={addSlide}>Add first slide</button>
          </div>
        )}
      </div>

      {pasteOpen && (
        <PasteImportModal
          hasExistingSlides={draft.slides.length}
          onApply={applyPastedSlides}
          onClose={() => setPasteOpen(false)}
        />
      )}

      {previewOpen && (
        <DraftPreview
          slides={draft.slides}
          draftName={draft.name}
          onClose={() => setPreviewOpen(false)}
        />
      )}
    </div>
  );
};

export default DraftComposer;
