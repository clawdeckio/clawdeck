# Add Missing Board Features

## Context
Read `DESIGN_SYSTEM.md` for all design tokens. Read `clawdeck-board-v3.jsx` as the visual reference for how each feature should look and behave. The board view already exists with columns, cards, card detail panel, priority dots, agent assign, and activity feed. These are the features that still need to be added.

---

## Feature 1: ⌘K Command Bar

A floating command bar that opens with `⌘K` (Mac) or `Ctrl+K` (Windows/Linux). This is the power-user entry point for quick search and agent commands.

### Layout
- Centered horizontally, positioned ~20% from top
- Width: 560px, border-radius: 16px
- Background: `#1e1e22`
- Border: `rgba(255,255,255,0.08)`
- Box shadow: `0 16px 48px rgba(0,0,0,0.5)`
- Backdrop overlay: `rgba(0,0,0,0.4)` covering full screen, click to close
- Animation: scale from 0.96 + fade in, centered (120ms)

### Two Modes (tabs at top of bar)
1. **Search mode** (default) — magnifying glass icon + "Search cards..." placeholder
2. **Agent mode** — 🤖 icon + "Ask your agent..." placeholder
- Tabs are small text buttons at top of the input area, active tab has a bottom border accent

### Input
- Full-width text input, 15px font, transparent background, no visible border
- Placeholder text in `#555`
- Auto-focus when opened

### Behavior
- `⌘K` / `Ctrl+K` toggles open/close
- `Escape` closes
- Click on backdrop closes
- Search mode: filters cards as you type (show matching cards below input as results)
- Agent mode: just the input for now, no backend needed yet — show a placeholder message like "Agent commands coming soon"

### Search Results (below input)
- List of matching cards, max 5 visible
- Each result row: project pill + card title + column badge
- Click a result to open that card's detail panel
- If no matches: "No cards found" in muted text

### Stimulus Controller: `command_bar_controller.js`
```
Targets: modal, backdrop, input, searchResults, searchTab, agentTab
Actions:
  - toggle (keyboard shortcut listener)
  - close
  - switchTab
  - search (input event, filters cards)
  - selectResult (click on result)
```

### ERB: `app/views/shared/_command_bar.html.erb`
Render this partial in the application layout so it's available on every page.

---

## Feature 2: Status Dropdown in Card Detail Panel

The card detail panel currently shows the status as a pill in the header (e.g. "Done"). Add a clickable dropdown in the Details section to change the card's column.

### Layout
- Inside the Details section, as a row: label "Status" on left, dropdown trigger on right
- Trigger: colored dot (matching current column) + column name + chevron icon
- Chevron rotates 180° when open

### Dropdown Menu
- Position: absolute, below the trigger, aligned right
- Width: 180px, padding: 4px, border-radius: 10px
- Background: `#222226`
- Border: `rgba(255,255,255,0.08)`
- Box shadow: `0 12px 40px rgba(0,0,0,0.5)`
- Animation: `dropIn` (fade + slide down 4px, 120ms)

### Menu Items
- One row per column: colored dot + column name
- Active column: `rgba(255,255,255,0.06)` background + checkmark SVG in column's dot color
- Hover: `rgba(255,255,255,0.04)` background
- Click: move card to that column (PATCH request), close dropdown, update the header pill too

### Click-outside-to-close
Reuse the existing dropdown Stimulus controller pattern.

---

## Feature 3: Agent Status Banner in Card Detail Panel

When a card has an agent assigned, show a status banner in the detail panel below the Details section.

### Two States

**Agent working:**
- Background: `rgba(251,191,36,0.05)` (amber tint)
- Border: `rgba(251,191,36,0.10)`
- Icon: 🤖 (16px)
- Title: "Agent is working on this" — amber text `#fbbf24`, 12px semibold
- Subtitle: "Check back soon for updates" — `#444`, 11px

**Agent finished:**
- Background: `rgba(52,211,153,0.05)` (green tint)
- Border: `rgba(52,211,153,0.10)`
- Icon: 🤖 (16px)
- Title: "Agent finished — needs review" — green text `#34d399`, 12px semibold
- Subtitle: "Review changes before moving to Done" — `#444`, 11px

### Behavior
- Only visible when the card has an agent assigned AND agent has a status
- Sits between the Details rows and the Subtasks section

---

## Feature 4: Subtasks with Progress Bar

Add a subtasks section to the card detail panel, below the agent banner.

### Layout
- Section header: "SUBTASKS" (10px, bold, uppercase, `#444`) + count "3/5" on right
- Progress bar: 3px tall, border-radius 2px, background `rgba(255,255,255,0.05)`, fill uses the card's project color at 80% opacity
- Subtask list below the progress bar

### Each Subtask Row
- Clickable row: background `rgba(255,255,255,0.03)`, border `rgba(255,255,255,0.04)`, border-radius 8px
- Checkbox: 16px square, border-radius 4px
  - Unchecked: `1.5px solid rgba(255,255,255,0.15)` border, transparent bg
  - Checked: project color fill + white checkmark SVG
- Title: 12.5px, medium weight
  - Active: `#bbb`
  - Done: `#444` + strikethrough

### Behavior
- Click anywhere on the row to toggle the subtask
- PATCH request to update subtask status
- Progress bar updates immediately (optimistic)
- Subtask count in header updates

### Data
If subtasks don't exist in the schema yet, add a migration:
```ruby
create_table :subtasks do |t|
  t.references :card, null: false, foreign_key: true
  t.string :title, null: false
  t.boolean :done, default: false
  t.integer :position
  t.timestamps
end
```

---

## Feature 5: Agent Suggestion Hints

Contextual hints that appear at the bottom of the card detail panel when relevant.

### Layout
- Background: `rgba(251,191,36,0.04)` (very subtle amber)
- Border: `rgba(251,191,36,0.08)`
- Border-radius: 10px
- Padding: 12px 14px
- Icon: 💡 (14px) on left
- Title: "Suggestion" — amber `#fbbf24`, 12px semibold
- Body text: description — `#888`, 12px medium, line-height 1.4

### Example Hints
- "This card has been in Inbox for 5 days — move it or drop it?"
- "Agent can help with this — want to assign?"
- "Draft is ready for review"

### Behavior
- Only shows when a hint exists for the card
- For now, hints can be a nullable `agent_hint` text column on the card model
- If the field is blank/null, the section doesn't render

---

## Feature 6: Card Hover States

Cards on the board should have a visible hover effect.

- Default border: `rgba(255,255,255,0.04)`
- Hover border: `rgba(255,255,255,0.08)`
- Transition: `border-color 120ms ease`
- Cursor: pointer

This is pure CSS, add it to the card partial's classes.

---

## Feature 7: Drag & Drop Visual Feedback

If drag & drop already exists, add these visual states. If it doesn't exist yet, implement it with SortableJS.

### Dragging Card
- Opacity: 0.4
- Slight scale: 1.02 (optional)

### Drop Zone (column receiving a card)
- Column background lightens slightly: add a 1px dashed border or subtle background change
- Or: column header dot pulses

### Implementation
- Use SortableJS with Stimulus
- On drop: PATCH request to update card's column (and position within column)
- Optimistic UI: card moves immediately in the DOM

---

## Implementation Order

1. **Status Dropdown** — quick win, improves card detail panel
2. **Agent Status Banner** — simple conditional render
3. **Subtasks** — may need migration
4. **Agent Suggestion Hints** — simple conditional render
5. **Card Hover States** — CSS only
6. **Drag & Drop Feedback** — enhance existing or add new
7. **Command Bar** — most complex, do last

For each feature: implement the ERB partial/view, create or update the Stimulus controller, add any needed routes/controller actions, test it works. Move to the next feature.
