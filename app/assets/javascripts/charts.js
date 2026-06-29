import Chartkick from 'chartkick';
import Chart from 'chart.js/auto';
import 'chartjs-adapter-date-fns';

window.Chartkick = Chartkick;
Chartkick.addAdapter(Chart);

// Usage page JavaScript functionality
const initUsage = () => {
    initWikiList();
    initCsvButton();
};

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initUsage);
} else {
    initUsage();
}

function initWikiList() {
    const container = document.getElementById('wiki-list-container');
    if (!container) return;

    const wikis = JSON.parse(container.dataset.wikis);
    const maxCount = wikis.length > 0 ? wikis[0].course_count : 0;
    const INITIAL_SHOW = 20;

    let currentTab = 'all';
    let searchQuery = '';
    let showAll = false;

    // Build the controls and table container
    container.innerHTML = `${buildControls()}<div id="wiki-table-area" role="tabpanel" aria-labelledby="wiki-tab-all" tabindex="0"></div>`;

    // Bind events
    bindSearchEvent();
    bindTabEvents();

    // Initial render
    renderTable();

    function buildControls() {
        return `
            <div class="wiki-controls">
                <input type="text" class="wiki-search" id="wiki-search" placeholder="Search wikis..." aria-label="Search wikis" />
                <div class="wiki-tabs" id="wiki-tabs" role="tablist">
                    <button class="wiki-tab active" data-tab="all" role="tab" id="wiki-tab-all" aria-selected="true" aria-controls="wiki-table-area" tabindex="0">All wikis</button>
                    <button class="wiki-tab" data-tab="top10" role="tab" id="wiki-tab-top10" aria-selected="false" aria-controls="wiki-table-area" tabindex="-1">Top 10</button>
                    <button class="wiki-tab" data-tab="project" role="tab" id="wiki-tab-project" aria-selected="false" aria-controls="wiki-table-area" tabindex="-1">By project</button>
                    <button class="wiki-tab" data-tab="language" role="tab" id="wiki-tab-language" aria-selected="false" aria-controls="wiki-table-area" tabindex="-1">By language</button>
                </div>
            </div>
        `;
    }

    function bindSearchEvent() {
        const searchInput = document.getElementById('wiki-search');
        searchInput.addEventListener('input', function () {
            searchQuery = this.value.toLowerCase();
            showAll = false;
            renderTable();
        });
    }

    function bindTabEvents() {
        const tabContainer = document.getElementById('wiki-tabs');
        const tabs = Array.from(tabContainer.querySelectorAll('.wiki-tab'));

        const activate = (tab) => {
            tabs.forEach((t) => {
                t.classList.remove('active');
                t.setAttribute('aria-selected', 'false');
                t.setAttribute('tabindex', '-1');
            });
            tab.classList.add('active');
            tab.setAttribute('aria-selected', 'true');
            tab.setAttribute('tabindex', '0');
            currentTab = tab.dataset.tab;
            showAll = false;
            renderTable();
        };

        tabContainer.addEventListener('click', (e) => {
            const tab = e.target.closest('.wiki-tab');
            if (!tab) return;
            activate(tab);
        });

        tabContainer.addEventListener('keydown', (e) => {
            if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return;
            const i = tabs.indexOf(document.activeElement);
            if (i === -1) return;
            e.preventDefault();
            const next = e.key === 'ArrowRight' ? (i + 1) % tabs.length : (i - 1 + tabs.length) % tabs.length;
            tabs[next].focus();
            activate(tabs[next]);
        });
    }

    function getFilteredWikis() {
        let filtered = wikis;

        if (searchQuery) {
            filtered = filtered.filter(w =>
                w.domain.toLowerCase().includes(searchQuery)
                || w.project.toLowerCase().includes(searchQuery)
                || (w.language && w.language.toLowerCase().includes(searchQuery))
            );
        }

        if (currentTab === 'top10') {
            filtered = filtered.slice(0, 10);
        }

        return filtered;
    }

    function renderTable() {
        const area = document.getElementById('wiki-table-area');

        if (currentTab === 'project') {
            renderGroupedView(area, 'project');
            return;
        }

        if (currentTab === 'language') {
            renderGroupedView(area, 'language');
            return;
        }

        const filtered = getFilteredWikis();
        const displayWikis = showAll ? filtered : filtered.slice(0, INITIAL_SHOW);
        const remaining = filtered.length - displayWikis.length;

        let html = buildTableHeader();
        html += '<tbody>';
        displayWikis.forEach((w) => {
            html += buildTableRow(w);
        });
        html += '</tbody></table>';

        if (remaining > 0) {
            html += `
                <div class="wiki-table-footer">
                    <span class="wiki-table-info">Showing ${displayWikis.length} of ${filtered.length} wikis</span>
                    <button class="wiki-show-all-btn" id="wiki-show-all">Show all</button>
                </div>
            `;
        } else if (filtered.length > INITIAL_SHOW) {
            html += `
                <div class="wiki-table-footer">
                    <span class="wiki-table-info">Showing all ${filtered.length} wikis</span>
                </div>
            `;
        } else if (filtered.length === 0) {
            html += '<div class="wiki-no-results">No wikis found matching your search.</div>';
        }

        area.innerHTML = html;

        // Bind show all button
        const showAllBtn = document.getElementById('wiki-show-all');
        if (showAllBtn) {
            showAllBtn.addEventListener('click', () => {
                showAll = true;
                renderTable();
            });
        }
    }

    function renderGroupedView(area, groupBy) {
        const filtered = getFilteredWikis();
        const groups = {};

        filtered.forEach((w) => {
            const key = groupBy === 'project' ? w.project : (w.language || 'Other');
            if (!groups[key]) groups[key] = [];
            groups[key].push(w);
        });

        // Sort groups by total course count
        const sortedGroups = Object.entries(groups).sort((a, b) => {
            const totalA = a[1].reduce((sum, w) => sum + w.course_count, 0);
            const totalB = b[1].reduce((sum, w) => sum + w.course_count, 0);
            return totalB - totalA;
        });

        let html = '';

        if (sortedGroups.length === 0) {
            html = '<div class="wiki-no-results">No wikis found matching your search.</div>';
            area.innerHTML = html;
            return;
        }

        sortedGroups.forEach(([groupName, groupWikis]) => {
            const totalCourses = groupWikis.reduce((sum, w) => sum + w.course_count, 0);
            const label = groupBy === 'project'
                ? `${groupWikis.length} wikis, ${totalCourses.toLocaleString()} courses`
                : `${groupWikis.length} projects, ${totalCourses.toLocaleString()} courses`;

            html += `
                <div class="wiki-group">
                    <div class="wiki-group-header">
                        <h3 class="wiki-group-name">${capitalize(groupName)}</h3>
                        <span class="wiki-group-count">(${label})</span>
                    </div>
                    ${buildTableHeader()}
                    <tbody>
            `;
            groupWikis.forEach((w) => {
                html += buildTableRow(w);
            });
            html += '</tbody></table></div>';
        });

        area.innerHTML = html;
    }

    function buildTableHeader() {
        return `
            <table class="wiki-table">
                <thead>
                    <tr>
                        <th>Wiki</th>
                        <th>Project</th>
                        <th>Courses</th>
                        <th class="wiki-bar-col">Activity</th>
                    </tr>
                </thead>
        `;
    }

    function buildTableRow(wiki) {
        const barWidth = maxCount > 0 ? Math.max(1, Math.round((wiki.course_count / maxCount) * 100)) : 0;
        let barClass = 'wiki-bar-low';
        if (barWidth > 25) barClass = 'wiki-bar-high';
        else if (barWidth > 8) barClass = 'wiki-bar-mid';

        return `
            <tr>
                <td><a href="/courses_by_wiki/${wiki.domain}" class="wiki-domain-link">${wiki.domain}</a></td>
                <td><span class="wiki-project-tag">${capitalize(wiki.project)}</span></td>
                <td class="wiki-course-count">${wiki.course_count.toLocaleString()}</td>
                <td class="wiki-bar-col">
                    <div class="wiki-bar-bg">
                        <div class="wiki-bar-fill ${barClass}" style="width: ${barWidth}%"></div>
                    </div>
                </td>
            </tr>
        `;
    }

    function capitalize(str) {
        if (!str) return '';
        return str.charAt(0).toUpperCase() + str.slice(1);
    }
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
