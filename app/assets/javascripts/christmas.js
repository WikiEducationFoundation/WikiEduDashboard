// Christmas Theme Animation
// Adds snowfall effect on page load

// Check if we're on the root page
function isRootPage() {
  const pathname = window.location.pathname;
  return pathname === '/' || pathname === '';
}

// Check if banner has already been shown
function hasBannerBeenShown() {
  return localStorage.getItem('christmasBannerShown') === 'true';
}

// Mark banner as shown
function markBannerAsShown() {
  localStorage.setItem('christmasBannerShown', 'true');
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

// Hide Christmas banner after a few seconds
function hideChristmasBanner() {
  const banner = document.querySelector('.christmas-banner');
  const wrapper = document.querySelector('.christmas-wrapper');
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

// Initialize Christmas theme - only on root page and only once
function initChristmasTheme() {
  const banner = document.querySelector('.christmas-banner');
  const snowfallContainer = document.getElementById('snowfall-container');
  const wrapper = document.querySelector('.christmas-wrapper');

  // Check if we should show the banner
  const shouldShow = isRootPage() && !hasBannerBeenShown();

  if (!shouldShow) {
    // Hide banner and snowfall if not on root or already shown
    if (banner) {
      banner.style.display = 'none';
    }
    if (snowfallContainer) {
      snowfallContainer.style.display = 'none';
    }
    if (wrapper) {
      wrapper.style.paddingTop = '0';
    }
    return;
  }

  // Show banner and animations
  markBannerAsShown();
  initChristmasAnimations();
  setTimeout(hideChristmasBanner, 7000);
}

// Run when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initChristmasTheme);
} else {
  // DOM is already ready
  initChristmasTheme();
}

