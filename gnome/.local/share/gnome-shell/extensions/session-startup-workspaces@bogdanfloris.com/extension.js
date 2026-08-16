// Puts the apps started from ~/.config/autostart on fixed workspaces.
//
// The stock auto-move-windows extension does this for every window an app ever
// opens, which means a terminal opened on workspace 5 in the middle of the day
// jumps back to workspace 2. This only acts during the first seconds of a
// session, so it places the login windows and then gets out of the way.

import GLib from 'gi://GLib';
import Shell from 'gi://Shell';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

// Workspace numbers as shown in the switcher (1-based), keyed by desktop id.
// Chrome ships two desktop files and which one a window resolves to depends on
// how it was launched, so both are listed.
const APP_WORKSPACES = {
    'google-chrome.desktop': 1,
    'com.google.Chrome.desktop': 1,
    'com.mitchellh.ghostty.desktop': 2,
};

const GRACE_PERIOD_MS = 30 * 1000;

// Recorded when the shell first imports this module, which happens while the
// session is starting up. It outlives the disable()/enable() cycle that a
// screen lock triggers, so unlocking hours later does not re-arm the grace
// period.
const MODULE_LOADED_US = GLib.get_monotonic_time();

export default class SessionStartupWorkspacesExtension extends Extension {
    enable() {
        const elapsedMs = (GLib.get_monotonic_time() - MODULE_LOADED_US) / 1000;
        const remainingMs = Math.ceil(GRACE_PERIOD_MS - elapsedMs);
        if (remainingMs <= 0)
            return;

        this._appWindows = new Map();
        this._appSystem = Shell.AppSystem.get_default();

        // The desktop files are usually known by the time the shell enables
        // extensions, but retry on installed-changed in case they are not.
        this._trackApps();
        this._appSystem.connectObject('installed-changed',
            () => this._trackApps(), this);

        this._timeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, remainingMs, () => {
            this._timeoutId = 0;
            this._stop();
            return GLib.SOURCE_REMOVE;
        });
    }

    disable() {
        if (this._timeoutId) {
            GLib.Source.remove(this._timeoutId);
            this._timeoutId = 0;
        }
        this._stop();
    }

    _stop() {
        if (!this._appWindows)
            return;

        for (const app of this._appWindows.keys())
            app.disconnectObject(this);
        this._appWindows = null;

        this._appSystem.disconnectObject(this);
        this._appSystem = null;
    }

    _trackApps() {
        for (const appId of Object.keys(APP_WORKSPACES)) {
            const app = this._appSystem.lookup_app(appId);
            if (!app || this._appWindows.has(app))
                continue;

            // Snapshot what is already open, so a shell restart mid-session
            // does not shuffle existing windows around.
            this._appWindows.set(app, app.get_windows());
            app.connectObject('windows-changed',
                () => this._onWindowsChanged(app), this);
        }
    }

    _onWindowsChanged(app) {
        const known = this._appWindows.get(app);
        const windows = app.get_windows();
        this._appWindows.set(app, windows);

        const workspaceIndex = APP_WORKSPACES[app.id] - 1;
        if (workspaceIndex >= global.workspace_manager.n_workspaces)
            return;

        for (const window of windows) {
            if (known.includes(window))
                continue;
            if (window.skip_taskbar || window.is_on_all_workspaces())
                continue;

            window.change_workspace_by_index(workspaceIndex, false);
        }
    }
}
