// Live Markdown preview for FAQ editor
import markdownIt from './utils/markdown_it';

const md = markdownIt({ html: true, linkify: true });

document.addEventListener('DOMContentLoaded', () => {
  const textarea = document.getElementById('faq_content');
  const preview = document.getElementById('faq_preview');

  if (!textarea || !preview) return;

  // Debounce function to avoid excessive re-renders
  let debounceTimer;
  const debounce = (callback, delay) => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(callback, delay);
  };

  // Update preview function
  const updatePreview = () => {
    const markdown = textarea.value;
    if (markdown.trim() === '') {
      preview.innerHTML = '<em>Start typing to see a live preview…</em>';
  } else {
      preview.innerHTML = md.render(markdown);
    }
  };

  // Sync scroll between textarea and preview
  textarea.addEventListener('scroll', () => {
    const scrollPercentage = textarea.scrollTop / (textarea.scrollHeight - textarea.clientHeight);
    preview.scrollTop = scrollPercentage * (preview.scrollHeight - preview.clientHeight);
  });

  // Listen to input events with debouncing
  textarea.addEventListener('input', () => {
    debounce(updatePreview, 150);
  });

  // Initial render if there's existing content
  if (textarea.value.trim() !== '') {
    updatePreview();
  }
});
