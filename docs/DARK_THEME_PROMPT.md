# Dark Theme Update Prompt

*Prompt for Claude Code to update PokéDeck colors to match maxie.bot style*

---

## Task: Update PokéDeck color scheme to match maxie.bot style

### Goal:
Change the app's color palette to a dark theme with warm accents. NO layout changes — colors and styling only.

### New Color Palette:

**Backgrounds:**
- Page background: `#0a0a0a` (near black)
- Card/panel background: `#141414` or `#1a1a1a` (dark gray)
- Hover states: slightly lighter (`#1f1f1f` or `#252525`)

**Text:**
- Primary text: `#ffffff` (white)
- Secondary text: `#a1a1a1` (gray-400 equivalent)
- Muted text: `#6b6b6b` (gray-500 equivalent)

**Accent (replace red-500):**
- Primary accent: `#f97316` (orange-500) — for links, buttons, highlights
- Hover: `#ea580c` (orange-600)
- Or use the coral from Cardy logo: `#F27B6A`

**Status colors:**
- Online/success: `#22c55e` (green-500)
- Warning/blocked: `#f59e0b` (amber-500)
- Error: `#ef4444` (red-500)

**Borders:**
- Subtle borders: `#262626` or `#2a2a2a`
- Or use `white/10` for transparency-based borders

### Implementation:

1. **Tailwind config (if customizing):**
   Add custom colors or use existing dark grays:
   ```js
   // tailwind.config.js
   theme: {
     extend: {
       colors: {
         surface: {
           DEFAULT: '#141414',
           hover: '#1f1f1f',
         },
         background: '#0a0a0a',
       }
     }
   }
   ```

2. **Or use Tailwind defaults:**
   - `bg-neutral-950` for page background
   - `bg-neutral-900` for cards
   - `text-white`, `text-neutral-400`, `text-neutral-500`
   - `orange-500` for accents

3. **Files to update:**
   - `app/views/layouts/application.html.erb` — body background
   - `app/views/layouts/home.html.erb` — landing page (keep white or match?)
   - `app/views/board/show.html.erb` — board background
   - `app/views/board/_header.html.erb` — header styling
   - `app/views/board/_column.html.erb` — column backgrounds
   - `app/views/board/_task_card.html.erb` — card styling
   - Any shared partials (navbar, flash, modals)
   - `app/assets/tailwind/application.css` if needed

4. **Replace throughout:**
   - `bg-stone-*` → `bg-neutral-900` or `bg-neutral-950`
   - `bg-white` → `bg-neutral-900`
   - `text-stone-*` → `text-white`, `text-neutral-400`
   - `bg-red-500` → `bg-orange-500`
   - `text-red-500` → `text-orange-500`
   - `border-stone-*` → `border-neutral-800` or `border-white/10`

5. **Cards should have:**
   - Dark background (`bg-neutral-900`)
   - Subtle border (`border border-white/10` or `border-neutral-800`)
   - Rounded corners (keep existing `rounded-md` or `rounded-lg`)
   - Hover state: slightly lighter background

6. **Buttons:**
   - Primary: `bg-orange-500 text-white hover:bg-orange-600`
   - Secondary: `bg-neutral-800 text-white hover:bg-neutral-700`

### Keep:
- All existing layouts and structure
- Font choices (Nunito)
- Border radius values
- Spacing/padding

### Landing page decision:
- Option A: Keep landing page white (contrast between marketing/app)
- Option B: Match dark theme everywhere

Recommend: Option A — white landing, dark app. Creates nice contrast when user logs in.

### Test:
- Check all pages after changes
- Ensure text is readable (contrast)
- Verify hover states are visible
- Check any charts/graphs if they exist
