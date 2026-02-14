# ClawDeck Design System
### For implementation in Rails + Tailwind CSS

> Reference prototypes: `clawdeck-home-v4.jsx` and `clawdeck-board-v3.jsx`
> These are React prototypes that define the target look and feel. Translate to ERB + Stimulus + Tailwind.

---

## Typography

**Font:** Plus Jakarta Sans (Google Fonts)  
Add to `application.html.erb` `<head>`:
```html
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
```

Tailwind config:
```js
fontFamily: {
  sans: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
}
```

**Weight scale:**
| Use | Weight | Tailwind |
|-----|--------|----------|
| Headlines / titles | 800 | `font-extrabold` |
| Section headers, card titles | 700 | `font-bold` |
| Labels, buttons, metadata | 600 | `font-semibold` |
| Body text, descriptions | 500 | `font-medium` |
| Never used | 400, 300 | — |

**Size scale:**
| Element | Size | Tailwind |
|---------|------|----------|
| Page title / greeting | 28px | `text-[28px]` |
| Card title (detail) | 20px | `text-xl` |
| Card title (surface) | 13.5px | `text-[13.5px]` |
| Section header | 13px | `text-[13px]` |
| Body / metadata | 12px | `text-xs` |
| Micro labels | 10-11px | `text-[10px]` / `text-[11px]` |

**Letter spacing:**
- Headlines: `tracking-[-0.03em]` (tight)
- Body: default
- Uppercase labels: `tracking-[0.06em]`

---

## Colors

### Backgrounds (3-layer depth system)
| Layer | Hex | Use | Tailwind |
|-------|-----|-----|----------|
| Base | `#0c0c0f` | Home screen bg, app chrome | `bg-[#0c0c0f]` |
| Surface | `#161619` | Board bg, dropdown bg, elevated panels | `bg-[#161619]` |
| Elevated | `#1a1a1e` | Detail panel, modals | `bg-[#1a1a1e]` |
| Card | `#1e1e22` | Cards, inputs, interactive surfaces | `bg-[#1e1e22]` |
| Dropdown menu | `#222226` | Dropdown menu panels | `bg-[#222226]` |

### Text
| Use | Hex | Tailwind |
|-----|-----|----------|
| Primary (headlines) | `#f0f0f0` | `text-[#f0f0f0]` |
| Secondary (body) | `#bbb` | `text-[#bbb]` |
| Tertiary (metadata) | `#888` | `text-[#888]` |
| Muted (labels, disabled) | `#555` | `text-[#555]` |
| Ghost (very muted) | `#444` | `text-[#444]` |
| Dimmed (timestamps) | `#333` | `text-[#333]` |

### Project Colors
These are the accent colors assigned per project. Used for: project pills, progress bars, column dots, card detail accents.
| Project | Color | Hex |
|---------|-------|-----|
| ClawDeck | Red | `#ef4444` |
| tini.bio | Green | `#34d399` |
| Gratu | Amber | `#fbbf24` |
| nod.so | Blue | `#60a5fa` |
| mx.works | Purple | `#a78bfa` |

### Functional Colors
| Role | Hex | Rule |
|------|-----|------|
| Agent | `#fbbf24` (amber) | ONLY for agent-related UI. Agent pills, agent status, agent icons. |
| Destructive / Logout | `#ef4444` (red) | ONLY for destructive actions. Never for priority. |
| Success / Agent done | `#34d399` (green) | Agent finished states, success confirmations. |
| Link / Info | `#60a5fa` (blue) | Low-priority indicators, informational. |

### Borders & Dividers
```
Subtle divider:    rgba(255,255,255,0.05)  → border-white/5
Card border:       rgba(255,255,255,0.04)  → border-white/[0.04]
Hover border:      rgba(255,255,255,0.08)  → border-white/[0.08]
Active border:     rgba(255,255,255,0.12)  → border-white/[0.12]
```

### Overlays
```
Backdrop:          rgba(0,0,0,0.4)         → bg-black/40
Subtle hover:      rgba(255,255,255,0.03)  → bg-white/[0.03]
Active state:      rgba(255,255,255,0.06)  → bg-white/[0.06]
Stronger active:   rgba(255,255,255,0.10)  → bg-white/10
```

---

## Spacing & Layout

### Border Radius
| Element | Radius | Tailwind |
|---------|--------|----------|
| Cards | 14px | `rounded-[14px]` |
| Buttons, pills, inputs | 7-8px | `rounded-lg` |
| Dropdown menus | 10px | `rounded-[10px]` |
| Dots, avatars | 50% | `rounded-full` |
| Subtask checkboxes | 4px | `rounded` |

### Card Padding
| Card type | Padding |
|-----------|---------|
| Task card (board) | `14px 16px` |
| Task card (home) | `14px 16px` |
| Detail panel | `20px` |
| Dropdown items | `8px 10px` |

### Grid & Layout
- Home: centered single column, `max-width: 680px`
- Board: full-width columns, `min-width: 220px` per column, scroll horizontal
- Nav bar: full-width, `height: 52px`, `padding: 0 20px`
- Detail panel: fixed right, `width: 400px`, full height

---

## Components

### 1. Nav Bar
Full-width top bar, height 52px. Three sections:
- **Left:** Board switcher dropdown (emoji + board name + chevron)
- **Center:** Stats ("3 inbox · 2 in progress" etc.)
- **Right:** User avatar circle (initial, clickable dropdown)

Background: transparent (sits on page bg).
Border bottom: `rgba(255,255,255,0.05)`.

### 2. Board Switcher Dropdown
Trigger: board emoji + name + rotating chevron.
Menu: list of boards with emoji + name. Active board has colored checkmark.
Bottom: "+ Create new board" with plus icon.
Menu background: `#161619` (home) or `#1e1e22` (board).
Menu border-radius: 12px. Box shadow: `0 12px 40px rgba(0,0,0,0.5)`.
Animation: `dropIn` (fade + slide down 4px, 120ms).

### 3. User Profile Dropdown
Trigger: avatar circle with initial.
Menu: user name + email header, then menu items (Profile, Settings, Agents, Billing), divider, red "Log out".
Same styling as board switcher menu.

### 4. Task Card (Board Surface)
Background: `#1e1e22`. Border: `rgba(255,255,255,0.04)`. Border-radius: 14px.
Layout:
```
[Title — 13.5px, font-bold, #e0e0e0]
[Bottom row: project pill | subtask fraction | agent indicator]
```
- **Project pill:** colored background at 10% opacity, colored text, 6px border-radius, font-semibold 10px
- **Subtask fraction:** "1/3" in muted text
- **Agent indicator:** amber dot (pulsing if working), or green dot (if done)
- **Drag:** opacity 0.4 while dragging
- Hover: border brightens to `rgba(255,255,255,0.08)`
- NO left color strip (removed in v4)

### 5. Task Card (Home Surface)
Similar to board card but includes:
- Time label on right side ("Morning", "11 AM", "Afternoon")
- Checkbox on left (circular, 18px, project-colored fill when done with white check SVG)
- Agent status pill if agent is active

### 6. Card Detail Panel (Slide-Over)
Fixed right panel, 400px wide, full height. Background: `#1a1a1e`.
Backdrop: `rgba(0,0,0,0.4)` overlay on click-to-close.
Animation: `slideIn` (fade + slide from right 16px, 200ms).

**Layout from top to bottom:**
1. Header bar: status pill (current column name in muted pill) + close ✕ button
2. Title: 20px, extrabold, `#f0f0f0`
3. Notes: textarea with placeholder "Add notes..."
4. **Details section** — labeled "Details", bold 13px header, then rows:
   - **Status:** label left, dropdown trigger right (dot + column name + chevron). Opens dropdown menu with all columns, active gets checkmark.
   - **Priority:** label left, 4 dot-buttons right. 1 dot = none (gray #555), 2 = low (blue #60a5fa), 3 = medium (amber #fbbf24), 4 = high (red #ef4444). Active button gets colored bg at 10% opacity + colored border.
   - **Agent:** label left, toggle pill right. Off: "Assign" in gray. On: "🤖 Assigned" in amber with amber bg.
5. Agent status banner (if agent assigned): amber or green card with icon + description
6. Subtasks: header with count, progress bar (project-colored), checkbox list
7. Agent suggestion hint (if present): yellow-tinted card with 💡
8. **Activity feed** — labeled "Activity", bold 13px header, then timeline:
   - Vertical line connector: `rgba(255,255,255,0.04)`, 1px wide, absolute positioned
   - Each event: 26px colored circle icon + text + timestamp
   - Icon colors: blue (created), purple (moved), green (priority change), amber (agent action)

### 7. Column Header (Board)
Layout: colored dot (8px) + label (13px, semibold) + count badge (muted).
"+ Add a card" button at bottom of each column.

### 8. Command Bar (⌘K)
Centered floating bar, 560px wide. Background: `#1e1e22`. Border-radius: 16px.
Two modes: search and agent chat (toggle tabs).
Input: 15px, no border, transparent bg.
Backdrop: `rgba(0,0,0,0.4)`.
Animation: `cmdIn` (scale from 0.96 + fade, centered).

### 9. Activity Chart (Home)
Stacked bar chart showing daily completed tasks: You (red `#ef4444`) vs Agent (amber `#fbbf24`).
- 7 bars (Mon–Sun), today is full saturation, past days 20% opacity
- Total count label above each bar
- Day labels below, today gets highlighted text color
- Summary row: completed / in progress / upcoming counts
- Legend row: "You (N)" and "Agent (N)" with colored dots
- **FLAT colors only. No gradients anywhere.**

### 10. Dropdown Menu (Generic)
Background: matches context (`#161619` on home, `#1e1e22` / `#222226` on board).
Border-radius: 10-12px. Border: `rgba(255,255,255,0.08)`.
Box shadow: `0 12px 40px rgba(0,0,0,0.5)`.
Items: 8-10px padding, 7px border-radius, hover bg `rgba(255,255,255,0.04)`.
Active item: `rgba(255,255,255,0.06)` bg.
Dividers: 1px `rgba(255,255,255,0.05)` margin 4px.

### 11. Project Pill / Badge
Small colored badge showing project identity.
- Background: project color at ~12% opacity
- Text: project color at full
- Font: 10px, semibold
- Padding: 3px 8px
- Border-radius: 6px

---

## Animations

Define these as Tailwind utilities or in your CSS:

```css
@keyframes fadeUp {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
@keyframes slideIn {
  from { opacity: 0; transform: translateX(16px); }
  to { opacity: 1; transform: translateX(0); }
}
@keyframes dropIn {
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
}
@keyframes cmdIn {
  from { opacity: 0; transform: translateX(-50%) scale(0.96); }
  to { opacity: 1; transform: translateX(-50%) scale(1); }
}
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.25; }
}
```

Timing:
- Dropdowns, hovers: 120-150ms
- Panel slide-in: 200ms
- Completion states: 300ms
- Drag physics: handled by Stimulus/SortableJS

---

## Interaction Patterns

### Click-outside-to-close
All dropdowns and floating panels close when clicking outside. Use Stimulus with a `click` listener on `document`.

### Keyboard shortcuts
| Key | Action |
|-----|--------|
| `⌘K` / `Ctrl+K` | Toggle command bar |
| `Escape` | Close any open panel, dropdown, or modal |

### Drag and drop
Cards are draggable between columns on the board view.  
Use SortableJS or similar. Dragging card: opacity 0.4. Drop zone: subtle border highlight.
Optimistic update: card moves immediately, sync in background.

### Optimistic UI
All state changes (check subtask, move card, change priority) update the UI immediately.
No loading spinners on primary actions.

---

## Anti-Patterns (NEVER DO)

- ❌ Gradients on anything
- ❌ Left color strips on cards (project identity is via colored pill only)
- ❌ Red for non-destructive purposes
- ❌ Multiple sidebars open at once
- ❌ Loading spinners on primary actions
- ❌ Inter or system fonts (always Plus Jakarta Sans)
- ❌ Inline wrapping button groups for status (use dropdowns)
- ❌ Dense tables with tiny text
- ❌ Tooltips containing critical information
- ❌ Confetti or gimmicky animations
- ❌ Light weight fonts (300, 400 for UI elements)

---

## File Structure (Rails)

```
app/
├── views/
│   ├── layouts/
│   │   └── application.html.erb     # Font import, base dark bg, nav partial
│   ├── shared/
│   │   ├── _navbar.html.erb          # Board switcher + stats + user dropdown
│   │   ├── _board_switcher.html.erb  # Board dropdown component
│   │   ├── _user_dropdown.html.erb   # User profile dropdown
│   │   ├── _command_bar.html.erb     # ⌘K floating command bar
│   │   └── _card_detail.html.erb     # Slide-over detail panel
│   ├── home/
│   │   └── show.html.erb             # Daily cockpit (greeting, tasks, chart)
│   ├── boards/
│   │   └── show.html.erb             # Kanban board view
│   └── cards/
│       └── _card.html.erb            # Task card partial (used on both screens)
├── javascript/
│   └── controllers/
│       ├── dropdown_controller.js     # Click-outside-to-close dropdown
│       ├── command_bar_controller.js   # ⌘K toggle + search/agent modes
│       ├── detail_panel_controller.js  # Slide-over open/close + content
│       ├── drag_controller.js          # SortableJS board drag & drop
│       ├── priority_controller.js      # Priority dot picker
│       └── card_controller.js          # Card interactions, checkbox toggle
```

---

## Implementation Order

1. **Tailwind config** — custom colors, font, animations
2. **Layout + navbar** — application layout, dark bg, Plus Jakarta Sans, nav bar with dropdowns
3. **Board view** — columns, card partials, drag & drop
4. **Card detail panel** — slide-over with all sections (status dropdown, priority, agent, activity, subtasks)
5. **Home view** — greeting, today's tasks, activity chart, agent updates
6. **Command bar** — ⌘K floating bar
7. **Polish** — animations, hover states, transitions
