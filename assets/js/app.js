/**
 * DB Compare - Main Application JavaScript
 * Handles theme toggle, form submission, results rendering, and interactivity.
 */

(function () {
    'use strict';

    // ============================================================
    //  THEME MANAGEMENT
    // ============================================================
    const ThemeManager = {
        init() {
            const saved = localStorage.getItem('db-compare-theme');
            if (saved) {
                this.set(saved);
            } else {
                // Default to system preference
                const systemDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
                this.set(systemDark ? 'dark' : 'light');
            }
            document.getElementById('themeToggle').addEventListener('click', () => {
                const current = document.documentElement.getAttribute('data-theme');
                this.set(current === 'dark' ? 'light' : 'dark');
            });
            // Listen for system theme changes
            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
                if (!localStorage.getItem('db-compare-theme')) {
                    this.set(e.matches ? 'dark' : 'light');
                }
            });
        },
        set(theme) {
            document.documentElement.setAttribute('data-theme', theme);
            localStorage.setItem('db-compare-theme', theme);
            const btn = document.getElementById('themeToggle');
            if (theme === 'dark') {
                btn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg> Light Mode`;
            } else {
                btn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg> Dark Mode`;
            }
        }
    };

    // ============================================================
    //  FORM HANDLING & API
    // ============================================================
    const App = {
        init() {
            ThemeManager.init();
            this.bindEvents();
        },

        bindEvents() {
            document.getElementById('compareForm').addEventListener('submit', (e) => {
                e.preventDefault();
                this.runComparison();
            });

            document.getElementById('clearBtn').addEventListener('click', () => {
                document.getElementById('resultsSection').innerHTML = '';
                document.getElementById('resultsSection').style.display = 'none';
            });

            // Tab switching
            document.addEventListener('click', (e) => {
                if (e.target.classList.contains('tab')) {
                    const tabGroup = e.target.closest('.tabs-container');
                    tabGroup.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
                    tabGroup.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
                    e.target.classList.add('active');
                    const target = e.target.getAttribute('data-tab');
                    tabGroup.querySelector(`#${target}`).classList.add('active');
                }
            });

            // Collapsible sections
            document.addEventListener('click', (e) => {
                const header = e.target.closest('.collapsible-header');
                if (header) {
                    header.classList.toggle('collapsed');
                    const body = header.nextElementSibling;
                    body.classList.toggle('collapsed');
                }
            });

            // Copy buttons
            document.addEventListener('click', (e) => {
                const btn = e.target.closest('.btn-copy');
                if (btn) {
                    const target = btn.getAttribute('data-copy-target');
                    const text = document.getElementById(target).textContent;
                    navigator.clipboard.writeText(text).then(() => {
                        btn.classList.add('copied');
                        const original = btn.textContent;
                        btn.textContent = 'Copied!';
                        setTimeout(() => {
                            btn.classList.remove('copied');
                            btn.textContent = original;
                        }, 2000);
                    });
                }
            });
        },

        async runComparison() {
            const form = document.getElementById('compareForm');
            const formData = new FormData(form);
            const data = {};
            formData.forEach((val, key) => { data[key] = val; });

            // Show spinner
            document.getElementById('spinner').classList.add('active');
            document.getElementById('resultsSection').style.display = 'none';

            try {
                const resp = await fetch('api.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(data),
                });
                const json = await resp.json();

                document.getElementById('spinner').classList.remove('active');

                if (!json.success) {
                    this.showError(json.error || 'Unknown error occurred.');
                    return;
                }

                this.renderResults(json.data);

            } catch (err) {
                document.getElementById('spinner').classList.remove('active');
                this.showError('Connection failed: ' + err.message);
            }
        },

        showError(msg) {
            const section = document.getElementById('resultsSection');
            section.style.display = 'block';
            section.innerHTML = `
                <div class="alert alert-error fade-in">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
                    <span>${this.esc(msg)}</span>
                </div>`;
        },

        renderResults(data) {
            const { results, fixSql, dbNameA, dbNameB } = data;
            const section = document.getElementById('resultsSection');
            section.style.display = 'block';

            let html = '';

            // --- Stats Bar ---
            const stats = results.stats;
            const hasDiffs = stats.totalDiffs > 0;
            html += `<div class="stats-bar fade-in">
                <div class="stat-card">
                    <div class="stat-value text-accent">${stats.tablesA}</div>
                    <div class="stat-label">Tables in ${this.esc(dbNameA)}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value text-success">${stats.tablesB}</div>
                    <div class="stat-label">Tables in ${this.esc(dbNameB)}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">${stats.commonTables}</div>
                    <div class="stat-label">Common Tables</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value ${hasDiffs ? 'text-danger' : 'text-success'}">${stats.totalDiffs}</div>
                    <div class="stat-label">Differences Found</div>
                </div>
            </div>`;

            if (!hasDiffs) {
                html += `<div class="card fade-in"><div class="card-body no-diff">
                    <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
                    <div>Databases are identical! No schema differences found.</div>
                </div></div>`;
                section.innerHTML = html;
                return;
            }

            // --- Tabs Container ---
            html += `<div class="tabs-container fade-in">
                <div class="tabs">
                    <div class="tab active" data-tab="tab-overview">Overview</div>
                    <div class="tab" data-tab="tab-tables">Missing Tables</div>
                    <div class="tab" data-tab="tab-columns">Column Diffs</div>
                    <div class="tab" data-tab="tab-indexes">Index Diffs</div>
                    <div class="tab" data-tab="tab-sql">SQL Fix Scripts</div>
                </div>`;

            // --- Tab: Overview ---
            html += `<div class="tab-content active" id="tab-overview">`;
            html += this.renderOverview(results, dbNameA, dbNameB);
            html += `</div>`;

            // --- Tab: Missing Tables ---
            html += `<div class="tab-content" id="tab-tables">`;
            html += this.renderMissingTables(results, dbNameA, dbNameB);
            html += `</div>`;

            // --- Tab: Column Diffs ---
            html += `<div class="tab-content" id="tab-columns">`;
            html += this.renderColumnDiffs(results, dbNameA, dbNameB);
            html += `</div>`;

            // --- Tab: Index Diffs ---
            html += `<div class="tab-content" id="tab-indexes">`;
            html += this.renderIndexDiffs(results, dbNameA, dbNameB);
            html += `</div>`;

            // --- Tab: SQL Fix Scripts ---
            html += `<div class="tab-content" id="tab-sql">`;
            html += this.renderSqlFixes(fixSql, dbNameA, dbNameB);
            html += `</div>`;

            html += `</div>`; // close tabs-container

            section.innerHTML = html;
        },

        renderOverview(results, dbNameA, dbNameB) {
            let html = '<div class="card"><div class="card-header"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg> Comparison Summary</div><div class="card-body">';

            const missingB = Object.keys(results.missingInB || {});
            const missingA = Object.keys(results.missingInA || {});
            const colDiffs = Object.keys(results.columnDiffs || {});
            const idxDiffs = Object.keys(results.indexDiffs || {});
            const fkDiffs  = Object.keys(results.fkDiffs || {});

            html += `<div class="table-wrapper"><table>
                <thead><tr><th>Category</th><th>Count</th><th>Status</th></tr></thead><tbody>
                <tr><td>Tables only in <strong>${this.esc(dbNameA)}</strong></td><td>${missingB.length}</td>
                    <td>${missingB.length ? `<span class="badge badge-missing">${missingB.length} missing</span>` : '<span class="badge badge-match">OK</span>'}</td></tr>
                <tr><td>Tables only in <strong>${this.esc(dbNameB)}</strong></td><td>${missingA.length}</td>
                    <td>${missingA.length ? `<span class="badge badge-missing">${missingA.length} missing</span>` : '<span class="badge badge-match">OK</span>'}</td></tr>
                <tr><td>Tables with column differences</td><td>${colDiffs.length}</td>
                    <td>${colDiffs.length ? `<span class="badge badge-diff">${colDiffs.length} differ</span>` : '<span class="badge badge-match">OK</span>'}</td></tr>
                <tr><td>Tables with index differences</td><td>${idxDiffs.length}</td>
                    <td>${idxDiffs.length ? `<span class="badge badge-diff">${idxDiffs.length} differ</span>` : '<span class="badge badge-match">OK</span>'}</td></tr>
                <tr><td>Tables with FK differences</td><td>${fkDiffs.length}</td>
                    <td>${fkDiffs.length ? `<span class="badge badge-diff">${fkDiffs.length} differ</span>` : '<span class="badge badge-match">OK</span>'}</td></tr>
            </tbody></table></div>`;

            html += '</div></div>';
            return html;
        },

        renderMissingTables(results, dbNameA, dbNameB) {
            let html = '';
            const missingB = results.missingInB || {};
            const missingA = results.missingInA || {};

            if (!Object.keys(missingB).length && !Object.keys(missingA).length) {
                html += `<div class="card"><div class="card-body"><div class="empty-state">
                    <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
                    <h3>No missing tables</h3><p>Both databases have the same set of tables.</p></div></div></div>`;
                return html;
            }

            if (Object.keys(missingB).length) {
                html += `<div class="card"><div class="card-header"><span class="badge badge-missing" style="margin-right:8px">${Object.keys(missingB).length}</span> Tables in <strong style="margin:0 4px">${this.esc(dbNameA)}</strong> missing from <strong style="margin-left:4px">${this.esc(dbNameB)}</strong></div>
                <div class="card-body"><div class="table-wrapper"><table>
                    <thead><tr><th>Table Name</th><th>Action</th></tr></thead><tbody>`;
                for (const [tbl, sql] of Object.entries(missingB)) {
                    html += `<tr><td><strong>${this.esc(tbl)}</strong></td><td><span class="diff-indicator removed">Missing in ${this.esc(dbNameB)}</span></td></tr>`;
                }
                html += `</tbody></table></div></div></div>`;
            }

            if (Object.keys(missingA).length) {
                html += `<div class="card"><div class="card-header"><span class="badge badge-missing" style="margin-right:8px">${Object.keys(missingA).length}</span> Tables in <strong style="margin:0 4px">${this.esc(dbNameB)}</strong> missing from <strong style="margin-left:4px">${this.esc(dbNameA)}</strong></div>
                <div class="card-body"><div class="table-wrapper"><table>
                    <thead><tr><th>Table Name</th><th>Action</th></tr></thead><tbody>`;
                for (const [tbl, sql] of Object.entries(missingA)) {
                    html += `<tr><td><strong>${this.esc(tbl)}</strong></td><td><span class="diff-indicator removed">Missing in ${this.esc(dbNameA)}</span></td></tr>`;
                }
                html += `</tbody></table></div></div></div>`;
            }

            return html;
        },

        renderColumnDiffs(results, dbNameA, dbNameB) {
            const diffs = results.columnDiffs || {};
            if (!Object.keys(diffs).length) {
                return `<div class="card"><div class="card-body"><div class="empty-state">
                    <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
                    <h3>No column differences</h3><p>All shared tables have identical column definitions.</p></div></div></div>`;
            }

            let html = '';
            for (const [table, cd] of Object.entries(diffs)) {
                html += `<div class="card">
                    <div class="collapsible-header">
                        <span><svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3"/><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"/></svg> <strong style="margin-left:6px">${this.esc(table)}</strong></span>
                        <span class="chevron"><svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg></span>
                    </div>
                    <div class="collapsible-body"><div class="card-body">`;

                // Missing columns
                const missingB = cd.missingInB || {};
                const missingA = cd.missingInA || {};
                const differing = cd.differing || {};

                if (Object.keys(missingB).length) {
                    html += `<p style="margin-bottom:8px"><span class="badge badge-missing">Missing in ${this.esc(dbNameB)}</span></p>
                    <div class="table-wrapper" style="margin-bottom:16px"><table>
                        <thead><tr><th>Column</th><th>Type</th><th>Nullable</th><th>Default</th><th>Extra</th></tr></thead><tbody>`;
                    for (const [col, meta] of Object.entries(missingB)) {
                        html += `<tr><td><strong>${this.esc(col)}</strong></td><td><code>${this.esc(meta.COLUMN_TYPE)}</code></td>
                            <td>${meta.IS_NULLABLE}</td><td>${meta.COLUMN_DEFAULT !== null ? this.esc(meta.COLUMN_DEFAULT) : '<em>NULL</em>'}</td>
                            <td>${this.esc(meta.EXTRA || '-')}</td></tr>`;
                    }
                    html += `</tbody></table></div>`;
                }

                if (Object.keys(missingA).length) {
                    html += `<p style="margin-bottom:8px"><span class="badge badge-missing">Missing in ${this.esc(dbNameA)}</span></p>
                    <div class="table-wrapper" style="margin-bottom:16px"><table>
                        <thead><tr><th>Column</th><th>Type</th><th>Nullable</th><th>Default</th><th>Extra</th></tr></thead><tbody>`;
                    for (const [col, meta] of Object.entries(missingA)) {
                        html += `<tr><td><strong>${this.esc(col)}</strong></td><td><code>${this.esc(meta.COLUMN_TYPE)}</code></td>
                            <td>${meta.IS_NULLABLE}</td><td>${meta.COLUMN_DEFAULT !== null ? this.esc(meta.COLUMN_DEFAULT) : '<em>NULL</em>'}</td>
                            <td>${this.esc(meta.EXTRA || '-')}</td></tr>`;
                    }
                    html += `</tbody></table></div>`;
                }

                if (Object.keys(differing).length) {
                    html += `<p style="margin-bottom:8px"><span class="badge badge-diff">Differing Definitions</span></p>
                    <div class="table-wrapper"><table>
                        <thead><tr><th>Column</th><th>${this.esc(dbNameA)}</th><th>${this.esc(dbNameB)}</th></tr></thead><tbody>`;
                    for (const [col, pair] of Object.entries(differing)) {
                        const aDesc = `${pair.a.COLUMN_TYPE} ${pair.a.IS_NULLABLE === 'NO' ? 'NOT NULL' : 'NULL'}${pair.a.COLUMN_DEFAULT !== null ? ' DEFAULT ' + pair.a.COLUMN_DEFAULT : ''}${pair.a.EXTRA ? ' ' + pair.a.EXTRA : ''}`;
                        const bDesc = `${pair.b.COLUMN_TYPE} ${pair.b.IS_NULLABLE === 'NO' ? 'NOT NULL' : 'NULL'}${pair.b.COLUMN_DEFAULT !== null ? ' DEFAULT ' + pair.b.COLUMN_DEFAULT : ''}${pair.b.EXTRA ? ' ' + pair.b.EXTRA : ''}`;
                        html += `<tr><td><strong>${this.esc(col)}</strong></td>
                            <td><span class="highlight-a">${this.esc(aDesc)}</span></td>
                            <td><span class="highlight-b">${this.esc(bDesc)}</span></td></tr>`;
                    }
                    html += `</tbody></table></div>`;
                }

                html += `</div></div></div>`;
            }
            return html;
        },

        renderIndexDiffs(results, dbNameA, dbNameB) {
            const diffs = results.indexDiffs || {};
            if (!Object.keys(diffs).length) {
                return `<div class="card"><div class="card-body"><div class="empty-state">
                    <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
                    <h3>No index differences</h3><p>All shared tables have identical indexes.</p></div></div></div>`;
            }

            let html = '';
            for (const [table, id] of Object.entries(diffs)) {
                html += `<div class="card">
                    <div class="collapsible-header">
                        <span><strong>${this.esc(table)}</strong></span>
                        <span class="chevron"><svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg></span>
                    </div>
                    <div class="collapsible-body"><div class="card-body">`;

                const missingB = id.missingInB || {};
                const missingA = id.missingInA || {};

                if (Object.keys(missingB).length) {
                    html += `<p style="margin-bottom:8px"><span class="badge badge-missing">Missing in ${this.esc(dbNameB)}</span></p>
                    <div class="table-wrapper" style="margin-bottom:16px"><table>
                        <thead><tr><th>Index Name</th><th>Unique</th><th>Columns</th></tr></thead><tbody>`;
                    for (const [name, idx] of Object.entries(missingB)) {
                        html += `<tr><td><strong>${this.esc(name)}</strong></td><td>${idx.unique ? 'Yes' : 'No'}</td><td>${this.esc(idx.columns.join(', '))}</td></tr>`;
                    }
                    html += `</tbody></table></div>`;
                }

                if (Object.keys(missingA).length) {
                    html += `<p style="margin-bottom:8px"><span class="badge badge-missing">Missing in ${this.esc(dbNameA)}</span></p>
                    <div class="table-wrapper" style="margin-bottom:16px"><table>
                        <thead><tr><th>Index Name</th><th>Unique</th><th>Columns</th></tr></thead><tbody>`;
                    for (const [name, idx] of Object.entries(missingA)) {
                        html += `<tr><td><strong>${this.esc(name)}</strong></td><td>${idx.unique ? 'Yes' : 'No'}</td><td>${this.esc(idx.columns.join(', '))}</td></tr>`;
                    }
                    html += `</tbody></table></div>`;
                }

                html += `</div></div></div>`;
            }
            return html;
        },

        renderSqlFixes(fixSql, dbNameA, dbNameB) {
            const sqlA = (fixSql.a || []).join('\n') || '-- No changes required';
            const sqlB = (fixSql.b || []).join('\n') || '-- No changes required';

            return `<div class="sql-fix-grid">
                <div class="card">
                    <div class="card-header" style="background:var(--accent-light)">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>
                        Apply on <strong style="margin-left:6px">${this.esc(dbNameA)}</strong>
                    </div>
                    <div class="card-body">
                        <div class="code-header">
                            <h5>SQL Statements</h5>
                            <button class="btn btn-copy" data-copy-target="sqlCodeA">Copy SQL</button>
                        </div>
                        <div class="code-block" id="sqlCodeA">${this.esc(sqlA)}</div>
                    </div>
                </div>
                <div class="card">
                    <div class="card-header" style="background:var(--success-bg)">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>
                        Apply on <strong style="margin-left:6px">${this.esc(dbNameB)}</strong>
                    </div>
                    <div class="card-body">
                        <div class="code-header">
                            <h5>SQL Statements</h5>
                            <button class="btn btn-copy" data-copy-target="sqlCodeB">Copy SQL</button>
                        </div>
                        <div class="code-block" id="sqlCodeB">${this.esc(sqlB)}</div>
                    </div>
                </div>
            </div>
            <div class="alert alert-info" style="margin-top:16px">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
                <span>Review the SQL statements carefully before executing them on your databases. Always back up your data first.</span>
            </div>`;
        },

        esc(str) {
            if (str === null || str === undefined) return '';
            const div = document.createElement('div');
            div.textContent = String(str);
            return div.innerHTML;
        }
    };

    // Initialize on DOM ready
    document.addEventListener('DOMContentLoaded', () => App.init());
})();
