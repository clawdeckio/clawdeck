# ClawDeck UI Migration Plan
### From current UI → Design System v2

---

## Context

ClawDeck is a Rails app with Tailwind CSS. The current UI works but needs to be updated to match the new design system defined in `DESIGN_SYSTEM.md`. Two reference prototypes exist as React files:

- `clawdeck-home-v4.jsx` — the target home screen
- `clawdeck-board-v3.jsx` — the target board screen with card detail panel

These are NOT to be used as React components. They are **visual references** for how the final ERB + Tailwind + Stimulus implementation should look and behave.

---

## Before You Start

1. Read `DESIGN_SYSTEM.md` thoroughly — it has every token, color, spacing value, and component spec.
2. Read both `.jsx` reference files to understand the layout, interactions, and data flow.
3. Audit the current codebase: find all views, partials, Stimulus controllers, and Tailwind config.
4. Do NOT create a separate design system gem or component library. Apply changes directly to existing views and partials.

---

## Phase 1: Foundation (Do First)

### 1.1 Tailwind Config
Update `tailwind.config.js`:
- Set font-family to Plus Jakarta Sans
- Add custom colors for all bg layers (`base`, `surface`, `elevated`, `card`)
- Add animation keyframes (`fadeUp`, `slideIn`, `dropIn`, `cmdIn`, `pulse`)
- Add animation utilities
- Extend border-radius if needed

### 1.2 Application Layout
Update `application.html.erb`:
- Add Google Fonts link for Plus Jakarta Sans
- Set body to `bg-[#0c0c0f] text-[#e0e0e0] font-sans`
- Add custom CSS for scrollbar styling, selection color (`::selection { background: #fbbf24; color: #161619; }`)
- Add the animation keyframes to the stylesheet

### 1.3 Shared Navbar
Create or update `_navbar.html.erb`:
- Full-width, 52px height, flex between left/center/right
- Left: board switcher dropdown (Stimulus controller)
- Center: board stats (inbox count, in-progress count)
- Right: user avatar dropdown (Stimulus controller)

### 1.4 Dropdown Stimulus Controller
Create `dropdown_controller.js`:
- Handles open/close toggle
- Click-outside-to-close
- ESC to close
- Works for board switcher, user menu, status dropdown, and any future dropdown

---

## Phase 2: Board View

### 2.1 Board Layout
Update board `show.html.erb`:
- Background: `#161619`
- Horizontal flex layout for columns with overflow scroll
- Each column: min-width 220px, flex-shrink-0

### 2.2 Column Component
Each column has:
- Header: colored dot + label + card count badge
- Card list: vertical stack with gap
- Footer: "+ Add a card" ghost button

### 2.3 Card Partial
Update `_card.html.erb`:
- Background `#1e1e22`, border `rgba(255,255,255,0.04)`, border-radius 14px
- Title: 13.5px, bold
- Bottom row: project pill (colored) + subtask fraction + agent dot
- NO left color strip
- Hover: border brightens
- Click: opens detail panel
- Draggable (data attributes for SortableJS)

### 2.4 Drag & Drop
Create `drag_controller.js`:
- Use SortableJS for column-to-column card movement
- Dragging state: card opacity 0.4
- Drop: PATCH request to update card column, optimistic UI update

---

## Phase 3: Card Detail Panel

### 3.1 Panel Structure
Create `_card_detail.html.erb` and `detail_panel_controller.js`:
- Fixed right panel, 400px wide, full height
- Background: `#1a1a1e`
- Backdrop overlay: `rgba(0,0,0,0.4)`, click to close
- Slide-in animation from right

### 3.2 Panel Sections (top to bottom)
1. **Header:** Status pill showing current column + close button
2. **Title:** 20px extrabold
3. **Notes:** textarea, auto-save on change
4. **Details section:**
   - Status dropdown (column picker)
   - Priority dots (4 levels)
   - Agent toggle (assign/unassign)
5. **Agent banner** (conditional)
6. **Subtasks** with progress bar and checkboxes
7. **Activity feed** with timeline

### 3.3 Priority Picker
Create `priority_controller.js`:
- 4 buttons with increasing dots
- Click to set priority
- PATCH request to update
- Active button gets colored background + border

### 3.4 Status Dropdown (in detail panel)
Reuse the dropdown Stimulus controller.
- Trigger: dot + column name + chevron
- Menu: list of all columns, active gets checkmark
- On select: PATCH to move card, close dropdown

### 3.5 Activity Feed
- Rendered server-side from card activity log
- Each entry: colored circle icon + description + timestamp
- Vertical line connector between entries
- Icon color by type: blue=created, purple=moved, green=priority, amber=agent

---

## Phase 4: Home View

### 4.1 Home Layout
Update home `show.html.erb`:
- Background: `#0c0c0f`
- Centered column, max-width 680px
- Greeting: "Good morning, {name}" — 28px, extrabold
- Subtitle: task count summary

### 4.2 Today's Tasks
- Card list with checkboxes
- Each card: checkbox + title + time label + project pill + agent indicator
- Checkbox: circular, 18px, project-colored fill on complete

### 4.3 Activity Chart
- Stacked bar chart: You (red) vs Agent (amber)
- 7 days, today highlighted
- Pure HTML/CSS bars (no chart library needed)
- Summary row below: completed / in progress / upcoming
- Legend: colored dots with counts

### 4.4 Agent Updates
- Card with amber accent
- List of recent agent activity lines with timestamps

### 4.5 Nudges
- Card with suggestions
- Each nudge: text + action button

---

## Phase 5: Command Bar

### 5.1 Command Bar
Create `_command_bar.html.erb` and `command_bar_controller.js`:
- ⌘K / Ctrl+K to toggle
- Centered floating bar, 560px wide
- Background: `#1e1e22`, border-radius 16px
- Backdrop overlay
- Search mode + Agent chat mode (tab toggle)
- ESC to close

---

## Phase 6: Polish

### 6.1 Animations
- Dropdown menus: `dropIn` animation (120ms)
- Detail panel: `slideIn` animation (200ms)
- Command bar: `cmdIn` animation (200ms)
- Cards: `fadeUp` stagger on page load

### 6.2 Hover States
- Cards: border brightens on hover
- Dropdown items: subtle bg on hover
- Buttons: appropriate hover feedback

### 6.3 Selection & Focus
- `::selection` color: amber bg, dark text
- Focus rings: subtle, matching component context

### 6.4 Responsive
- Home: already single-column centered
- Board: horizontal scroll on smaller screens
- Detail panel: full-screen overlay on mobile (< 768px)
- Nav: adapt for mobile (bottom nav eventually)

---

## Notes

- Every color, spacing, and font value is documented in `DESIGN_SYSTEM.md`. Reference it.
- The `.jsx` files are REFERENCE ONLY — do not install React. Translate patterns to ERB + Stimulus + Turbo.
- Use Turbo Frames for partial page updates (card detail loading, card state changes).
- Use Turbo Streams for real-time agent updates if websockets are set up.
- All state changes should be optimistic — update DOM immediately, then send PATCH/POST.
- Test on dark backgrounds only. Light mode is future work.
