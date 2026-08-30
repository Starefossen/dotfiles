# ADR 0001: Browser Profile Routing and Isolation Strategy

## Context & Problem Statement

Currently, macOS handles URL routing via **Finicky** (`~/.finicky.js`), which intercepts external link clicks (e.g., from Slack, Mail, Terminal) and routes them to specific Safari Profiles (Work/NAV, Developer, Social, Personal) or native apps (Figma).

However, **Finicky cannot intercept internal clicks** (links clicked from within a web page inside Safari). 

Furthermore, Safari uses a strictly window-based profile model and lacks extension APIs to intercept internal navigation to force tabs into different profile windows. This creates friction compared to Firefox Multi-Account Containers, where internal link clicks can trigger automatic redirection into isolated, tab-based containers.

## Analysis of the Technical Limitation

1. **macOS URL Handling**: Finicky acts as a default browser replacement. Internal browser clicks bypass macOS URL handling entirely.
2. **Safari Profiles vs. Firefox Containers**: 
   * **Firefox**: Tab-level isolation. Extensions have deep API access to intercept web requests and move tabs between containers.
   * **Safari**: Window-level isolation. No native or extension-level API exists to intercept internal clicks and route them across profile windows. Safari's native "Open Links With Profile" feature suffers from the exact same limitation as Finicky (only applies to external clicks).

## Proposed Options (Put on hold)

This decision is currently deferred, but the following options were identified for future consideration:

### Option 1: The "Send to Finicky" Manual Escape Hatch (Safari)
Create an AppleScript or macOS Shortcut bound to a global hotkey (e.g., `Cmd + Shift + O`). When an internal link opens in the wrong Safari profile window:
1. The script grabs the URL of the active tab.
2. Closes the active tab.
3. Sends the URL to macOS via `open <URL>`.
4. Finicky intercepts it and routes it to the correct Safari profile window.

**Pros:** Keeps Safari as the main browser, utilizes existing Finicky config.
**Cons:** Requires manual intervention upon clicking a misrouted link.

### Option 2: Return to Firefox + Containers
Re-adopt Firefox and the Multi-Account Containers extension for internal browsing, while retaining Finicky as the macOS default browser to route external links into Firefox.

**Pros:** Seamless internal routing and isolation without manual intervention. Tab-based isolation requires fewer windows.
**Cons:** Loss of Safari-specific features, battery efficiency, and ecosystem integration.

### Option 3: Migrate to Arc Browser
Adopt Arc, which utilizes "Spaces" (Profiles) and features built-in "Air Traffic Control" for Finicky-style link routing.

**Pros:** Modern tab management and built-in routing logic.
**Cons:** High switching cost, new browser paradigm to learn.

## Decision

**Status:** Deferred / Pinned.

We are pausing action on this until the friction in Safari becomes a high enough priority to warrant either a manual workaround (Option 1) or a browser migration (Options 2/3).
