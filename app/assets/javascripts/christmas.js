// Celebration Banner Animation
// Generic system for holiday/celebration banners with snowfall effects

// Check if banner has already been shown (per celebration type)
function hasBannerBeenShown(celebrationType) {
  const key = `celebrationBannerShown_${celebrationType}`;
  return localStorage.getItem(key) === 'true';
}

// Mark banner as shown
function markBannerAsShown(celebrationType) {
  const key = `celebrationBannerShown_${celebrationType}`;
  localStorage.setItem(key, 'true');
}

// Clear all celebration banner flags (useful when settings are updated)
function clearAllBannerFlags() {
  const keys = Object.keys(localStorage);
  keys.forEach((key) => {
    if (key.startsWith('celebrationBannerShown_')) {
      localStorage.removeItem(key);
    }
  });
}

// Export for use in other modules
if (typeof window !== 'undefined') {
  window.clearCelebrationBannerFlags = clearAllBannerFlags;
}

// Initialize Christmas animations when DOM is ready
function initChristmasAnimations() {
  // Small delay to ensure DOM is fully ready
  setTimeout(() => {
    const snowfallContainer = document.getElementById('snowfall-container');
    if (!snowfallContainer) {
      return;
    }

    // Ensure container is visible
    snowfallContainer.style.display = 'block';

    // Create snowfall effect
    const snowflakes = ['❄', '❅', '❆'];
    const numSnowflakes = 50;

    for (let i = 0; i < numSnowflakes; i += 1) {
      setTimeout(() => {
        const snowflake = document.createElement('div');
        snowflake.className = 'snowflake';
        snowflake.textContent = snowflakes[Math.floor(Math.random() * snowflakes.length)];
        snowflake.style.left = `${Math.random() * 100}%`;
        snowflake.style.top = '0px';
        snowflake.style.opacity = Math.random() * 0.4 + 0.6;
        snowflake.style.fontSize = `${Math.random() * 20 + 20}px`;
        const duration = Math.random() * 4 + 4;
        snowflake.style.animationDuration = `${duration}s`;
        snowflake.style.animationDelay = '0s';
        snowfallContainer.appendChild(snowflake);

        // Remove snowflake after animation
        setTimeout(() => {
          if (snowflake.parentNode) {
            snowflake.parentNode.removeChild(snowflake);
          }
        }, (duration + 1) * 1000);
      }, i * 80);
    }

    // Clean up container after animations complete
    setTimeout(() => {
      if (snowfallContainer && snowfallContainer.children.length === 0) {
        snowfallContainer.style.display = 'none';
      }
    }, 15000);
  }, 100);
}

// Hide celebration banner after configured time
function hideCelebrationBanner(_autoHideSeconds) {
  const banner = document.querySelector('.celebration-banner');
  const wrapper = document.querySelector('.celebration-wrapper');
  if (banner) {
    // Add fade-out class
    banner.classList.add('fade-out');
    // Remove banner and adjust padding after animation
    setTimeout(() => {
      banner.style.display = 'none';
      if (wrapper) {
        wrapper.style.paddingTop = '0';
      }
    }, 500); // Match CSS animation duration
  }
}

// Initialize celebration theme
function initCelebrationTheme() {
  const banner = document.querySelector('.celebration-banner');
  const snowfallContainer = document.getElementById('snowfall-container');
  const wrapper = document.querySelector('.celebration-wrapper');

  if (!banner) {
    // No banner to show
    if (wrapper) {
      wrapper.style.paddingTop = '0';
    }
    return;
  }

  // Get configuration from data attributes
  const celebrationType = banner.dataset.celebrationType || 'generic';
  const autoHideSeconds = parseInt(banner.dataset.autoHide || '7');
  // Data attributes are always strings, so we need to check for the string "true"
  // Only show snowfall if explicitly set to "true"
  const showSnowfall = banner.dataset.showSnowfall === 'true';

  // Check if banner has already been shown for this celebration type
  if (hasBannerBeenShown(celebrationType)) {
    // Hide banner if already shown
    banner.style.display = 'none';
    if (snowfallContainer) {
      snowfallContainer.style.display = 'none';
    }
    if (wrapper) {
      wrapper.style.paddingTop = '0';
    }
    return;
  }

  // Show banner and animations
  markBannerAsShown(celebrationType);

  if (showSnowfall && snowfallContainer) {
    initChristmasAnimations();
  }

  setTimeout(() => hideCelebrationBanner(autoHideSeconds), autoHideSeconds * 1000);
}

// Run when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initCelebrationTheme);
} else {
  // DOM is already ready
  initCelebrationTheme();
}

