// Returns an onKeyDown handler that calls `handler` when Enter or Space is
// pressed. For non-button elements (div/li/span/p) made interactive via
// role="button" + tabIndex={0}, this provides the keyboard activation that
// native <button> elements get for free. Native <button> doesn't need this.
export const onEnterOrSpace = handler => (e) => {
  if (e.key === 'Enter' || e.key === ' ') {
    e.preventDefault();
    handler(e);
  }
};
