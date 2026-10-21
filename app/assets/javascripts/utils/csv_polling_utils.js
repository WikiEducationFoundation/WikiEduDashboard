export const DEFAULT_POLL_INTERVAL_MS = 6000;
export const DEFAULT_MAX_POLL_ATTEMPTS = 20;

/**
 * Polls a report CSV endpoint that follows the { status, url } JSON / 202 contract.
 * Uses recursive setTimeout to prevent overlapping requests.
 * Reports structured error objects with reason ('timeout', 'validation', 'server', 'network')
 * so callers can present appropriate localized messages.
 *
 * @param {string} url - The report URL to poll
 * @param {object} callbacks - { onReady, onError, onGenerating }
 * @param {object} options - { intervalMs, maxAttempts }
 * @returns {function} cancel - Function to cancel polling
 */
export const pollReportCsv = (url, callbacks = {}, options = {}) => {
  const { onReady, onError, onGenerating } = callbacks;
  const intervalMs = options.intervalMs || DEFAULT_POLL_INTERVAL_MS;
  const maxAttempts = options.maxAttempts || DEFAULT_MAX_POLL_ATTEMPTS;

  let attempts = 0;
  let timerId = null;
  let cancelled = false;

  const cancel = () => {
    cancelled = true;
    if (timerId) {
      clearTimeout(timerId);
      timerId = null;
    }
  };

  const poll = async () => {
    if (cancelled) return;
    attempts += 1;

    try {
      const response = await fetch(url, {
        headers: { Accept: 'application/json' },
        credentials: 'same-origin'
      });

      if (cancelled) return;

      if (response.status === 422) {
        const data = await response.json().catch(() => ({}));
        if (onError) onError({ reason: 'validation', message: data.error, status: 422 });
        return;
      }

      if (!response.ok && response.status !== 202) {
        if (onError) onError({ reason: 'server', status: response.status, message: 'Server error' });
        return;
      }

      const data = await response.json();
      if (cancelled) return;

      if (data.status === 'ready' && data.url) {
        if (onReady) onReady(data);
        return;
      }

      if (attempts < maxAttempts) {
        if (onGenerating) onGenerating(data);
        timerId = setTimeout(poll, intervalMs);
      } else if (onError) {
        onError({ reason: 'timeout', message: 'Timed out waiting for report generation' });
      }
    } catch (err) {
      if (cancelled) return;
      if (onError) onError({ reason: 'network', message: err.message || 'Network error' });
    }
  };

  poll();

  return cancel;
};
