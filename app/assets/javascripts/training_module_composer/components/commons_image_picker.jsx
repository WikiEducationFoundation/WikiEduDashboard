/* eslint-disable i18next/no-literal-string */
import React, { useState, useEffect } from 'react';

const LAYOUTS = [
  { value: 'alt-layout-100', label: 'Full width', width: 1280 },
  { value: 'alt-layout-50', label: 'Centered, 50%', width: 960 },
  { value: 'alt-layout-40-right', label: 'Float right, 40%', width: 500 },
  { value: 'alt-layout-40-left', label: 'Float left, 40%', width: 500 },
  { value: 'alt-layout-30-right', label: 'Float right, 30%', width: 330 },
  { value: 'alt-layout-30-left', label: 'Float left, 30%', width: 330 },
];

const COMMONS_FILE_PAGE = /^https?:\/\/commons\.wikimedia\.org\/wiki\/(File:[^?#]+)/i;
const WIKI_FILE_PAGE = /^https?:\/\/[a-z]+\.wikipedia\.org\/wiki\/(File:[^?#]+)/i;
const UPLOAD_THUMB = /^https?:\/\/upload\.wikimedia\.org\/wikipedia\/[^/]+\/thumb\/[0-9a-f]\/[0-9a-f]{2}\/([^/]+)\/[0-9]+px-/i;
const UPLOAD_DIRECT = /^https?:\/\/upload\.wikimedia\.org\/wikipedia\/[^/]+\/[0-9a-f]\/[0-9a-f]{2}\/([^/?#]+)$/i;
const BARE_FILE = /^File:.+/i;

const extractTitle = (input) => {
  const trimmed = input.trim();
  if (!trimmed) return null;
  const commonsPage = trimmed.match(COMMONS_FILE_PAGE);
  if (commonsPage) return decodeURIComponent(commonsPage[1]);
  const wikiPage = trimmed.match(WIKI_FILE_PAGE);
  if (wikiPage) return decodeURIComponent(wikiPage[1]);
  const uploadThumb = trimmed.match(UPLOAD_THUMB);
  if (uploadThumb) return `File:${decodeURIComponent(uploadThumb[1])}`;
  const uploadDirect = trimmed.match(UPLOAD_DIRECT);
  if (uploadDirect) return `File:${decodeURIComponent(uploadDirect[1])}`;
  if (BARE_FILE.test(trimmed)) return trimmed;
  return null;
};

const fetchImageInfo = async (title, width, signal) => {
  const params = new URLSearchParams({
    action: 'query',
    prop: 'imageinfo',
    titles: title,
    iiprop: 'url|size',
    iiurlwidth: String(width),
    format: 'json',
    origin: '*',
  });
  const response = await fetch(
    `https://commons.wikimedia.org/w/api.php?${params}`,
    { signal }
  );
  if (!response.ok) throw new Error(`Commons API error (${response.status})`);
  const data = await response.json();
  const pages = data && data.query && data.query.pages;
  if (!pages) throw new Error('Unexpected Commons API response');
  const page = Object.values(pages)[0];
  if (page.missing !== undefined) {
    throw new Error('File not found on Wikimedia Commons');
  }
  const info = page.imageinfo && page.imageinfo[0];
  if (!info || !info.thumburl) throw new Error('No thumbnail available');
  return {
    thumburl: info.thumburl,
    width: info.thumbwidth,
    height: info.thumbheight,
    canonicalTitle: page.title,
  };
};

const buildMarkup = ({ layoutClass, thumburl, caption, smallCaption }) => {
  const trimmed = caption.trim();
  const captionTag = smallCaption ? '<figcaption class="image-credit">' : '<figcaption>';
  const captionBlock = trimmed
    ? `\n  ${captionTag}\n    ${trimmed}\n  </figcaption>`
    : '';
  return `<figure class="${layoutClass}">\n  <img src="${thumburl}" />${captionBlock}\n</figure>\n`;
};

const CommonsImagePicker = ({ onInsert, onClose }) => {
  const [url, setUrl] = useState('');
  const [layout, setLayout] = useState('alt-layout-100');
  const [caption, setCaption] = useState('');
  const [smallCaption, setSmallCaption] = useState(false);
  const [resolved, setResolved] = useState(null);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);

  const title = extractTitle(url);
  const layoutInfo = LAYOUTS.find(l => l.value === layout);
  const width = layoutInfo.width;

  useEffect(() => {
    if (!title) {
      setResolved(null);
      setError(null);
      return undefined;
    }
    const controller = new AbortController();
    const timer = setTimeout(() => {
      setBusy(true);
      setError(null);
      fetchImageInfo(title, width, controller.signal)
        .then((info) => { setResolved(info); setBusy(false); })
        .catch((e) => {
          if (e.name === 'AbortError') return;
          setResolved(null);
          setError(e.message);
          setBusy(false);
        });
    }, 350);
    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [title, width]);

  const handleInsert = (event) => {
    event.preventDefault();
    if (!resolved) return;
    onInsert(buildMarkup({
      layoutClass: layout,
      thumburl: resolved.thumburl,
      caption,
      smallCaption,
    }));
  };

  const trimmedCaption = caption.trim();
  const showUnreadable = !!url.trim() && !title;

  return (
    <div className="training_module_composer__modal__backdrop" role="presentation" onClick={onClose}>
      <div
        className="training_module_composer__modal training_module_composer__image_picker"
        role="dialog"
        aria-labelledby="commons_image_picker_title"
        onClick={e => e.stopPropagation()}
      >
        <h2 id="commons_image_picker_title">Insert Commons image</h2>
        <form onSubmit={handleInsert}>
          <div className="training_module_composer__field">
            <label htmlFor="commons_image_url">Commons URL or File: title</label>
            <input
              id="commons_image_url"
              type="text"
              value={url}
              onChange={e => setUrl(e.target.value)}
              placeholder="https://commons.wikimedia.org/wiki/File:Example.jpg"
              autoFocus
            />
            <small>
              A Commons file page URL, an upload.wikimedia.org URL, or a File: title.
            </small>
          </div>

          <div className="training_module_composer__image_picker__row">
            <div className="training_module_composer__field">
              <label htmlFor="commons_image_layout">Layout</label>
              <select
                id="commons_image_layout"
                value={layout}
                onChange={e => setLayout(e.target.value)}
              >
                {LAYOUTS.map(l => (
                  <option key={l.value} value={l.value}>{l.label}</option>
                ))}
              </select>
              <small>Requests a {width}px-wide thumbnail.</small>
            </div>

            <div className="training_module_composer__field">
              <label htmlFor="commons_image_caption">Caption (optional)</label>
              <textarea
                id="commons_image_caption"
                rows={2}
                value={caption}
                onChange={e => setCaption(e.target.value)}
              />
              <label className="training_module_composer__image_picker__inline_check">
                <input
                  type="checkbox"
                  checked={smallCaption}
                  onChange={e => setSmallCaption(e.target.checked)}
                  disabled={!trimmedCaption}
                />
                Small / credit style
              </label>
            </div>
          </div>

          <div className="training_module_composer__image_picker__preview">
            <label>Preview</label>
            <div className="training__slide training_module_composer__image_picker__preview__stage">
              {busy && <p className="training_module_composer__image_picker__status">Loading…</p>}
              {error && <div className="notification error">{error}</div>}
              {showUnreadable && !busy && (
                <p className="training_module_composer__image_picker__status">
                  Couldn’t read that as a Commons URL.
                </p>
              )}
              {resolved && !busy && !error && (
                <figure className={layout}>
                  <img src={resolved.thumburl} alt="" />
                  {trimmedCaption && (
                    smallCaption
                      ? <figcaption className="image-credit">{trimmedCaption}</figcaption>
                      : <figcaption>{trimmedCaption}</figcaption>
                  )}
                </figure>
              )}
            </div>
          </div>

          <div className="training_module_composer__modal__actions">
            <button type="button" className="button" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="button dark" disabled={!resolved || busy}>
              Insert
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CommonsImagePicker;
