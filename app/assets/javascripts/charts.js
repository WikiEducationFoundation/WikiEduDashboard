import Chartkick from 'chartkick';
import Chart from 'chart.js/auto';
import 'chartjs-adapter-date-fns';

window.Chartkick = Chartkick;
Chartkick.addAdapter(Chart);

// Usage page JavaScript functionality
const initUsage = () => {
    initWikiDropdown();
    initCsvButton();
};

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initUsage);
} else {
    initUsage();
}

function initWikiDropdown() {
    const dropdown = document.getElementById('wiki-view-dropdown');
    if (!dropdown) return;

    const sortSections = document.querySelectorAll('.wiki-sort-section');

    dropdown.addEventListener('change', function () {
        const selectedView = this.value;

        // Hide all sections
        sortSections.forEach((section) => {
            section.style.display = 'none';
        });

        // Show selected section
        const selectedSection = document.getElementById(`wiki-list-${selectedView}`);
        if (selectedSection) {
            selectedSection.style.display = 'block';
        }
    });
}

function initCsvButton() {
    document.addEventListener('click', (e) => {
        const btn = e.target.closest('#csv-btn');
        if (!btn) return;

        if (btn.dataset.locked === 'true') {
            e.preventDefault();
            return;
        }

        btn.dataset.locked = 'true';
        btn.textContent = 'Generating CSV. This may take a while...';
        btn.style.pointerEvents = 'none';
        btn.style.opacity = '0.6';

        setTimeout(() => {
            btn.dataset.locked = 'false';
            btn.textContent = 'Generate CSV of all programs';
            btn.style.pointerEvents = '';
            btn.style.opacity = '';
        }, 300000);
    });
}
