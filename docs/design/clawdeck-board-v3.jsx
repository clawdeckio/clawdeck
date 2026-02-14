import { useState, useEffect, useRef } from "react";

const PROJECTS = [
  { id: "clawdeck", name: "ClawDeck Cloud", emoji: "🦞", color: "#ef4444" },
  { id: "tini", name: "tini.bio", emoji: "🔗", color: "#34d399" },
  { id: "gratu", name: "Gratu", emoji: "🙏", color: "#fbbf24" },
  { id: "nod", name: "nod.so", emoji: "📬", color: "#60a5fa" },
  { id: "mx", name: "mx.works", emoji: "⚡", color: "#a78bfa" },
];

const COLUMNS = [
  { id: "inbox", label: "Inbox", dot: "#666" },
  { id: "up_next", label: "Up Next", dot: "#60a5fa" },
  { id: "in_progress", label: "In Progress", dot: "#fbbf24" },
  { id: "in_review", label: "In Review", dot: "#a78bfa" },
  { id: "done", label: "Done", dot: "#34d399" },
];

const BOARDS = [
  { id: "clawdeck-cloud", name: "ClawDeck Cloud", emoji: "🦞", color: "#ef4444" },
  { id: "personal", name: "Personal", emoji: "🏠", color: "#60a5fa" },
  { id: "mx-works", name: "mx.works", emoji: "⚡", color: "#a78bfa" },
  { id: "client-projects", name: "Client Projects", emoji: "💼", color: "#34d399" },
];

const PRIORITY_LEVELS = [
  { id: "none", label: "None", dots: 1, color: "#555" },
  { id: "low", label: "Low", dots: 2, color: "#60a5fa" },
  { id: "medium", label: "Medium", dots: 3, color: "#fbbf24" },
  { id: "high", label: "High", dots: 4, color: "#ef4444" },
];

const INIT_TASKS = [
  { id: 1, title: "Explore AppSumo listing", project: "tini", column: "inbox", subtasks: null, agent: false, agentStatus: null, notes: "", agentHint: null, priority: 1, priorityLevel: "none", activity: [
    { type: "created", time: "3 days ago" },
  ]},
  { id: 2, title: "Research competitor pricing", project: "nod", column: "inbox", subtasks: null, agent: false, agentStatus: null, notes: "Look at Buttondown, Kit, Mailchimp pricing pages", agentHint: "Want me to research this?", priority: 2, priorityLevel: "low", activity: [
    { type: "priority", from: "none", to: "low", time: "2 days ago" },
    { type: "created", time: "4 days ago" },
  ]},
  { id: 3, title: "Integrate Polar.sh payments", project: "clawdeck", column: "up_next", subtasks: [
    { id: "3a", title: "Set up Polar.sh account", done: true },
    { id: "3b", title: "Implement webhook handler", done: false },
    { id: "3c", title: "Create billing settings page", done: false },
  ], agent: true, agentStatus: "working", notes: "", agentHint: null, priority: 1, priorityLevel: "high", activity: [
    { type: "agent", action: "started working", time: "1 hour ago" },
    { type: "moved", from: "Inbox", to: "Up Next", time: "2 days ago" },
    { type: "priority", from: "medium", to: "high", time: "3 days ago" },
    { type: "created", time: "5 days ago" },
  ]},
  { id: 4, title: "Create subscription expiry job", project: "clawdeck", column: "up_next", subtasks: [
    { id: "4a", title: "Define expiry logic", done: false },
    { id: "4b", title: "Add background worker", done: false },
  ], agent: false, agentStatus: null, notes: "", agentHint: null, priority: 2, priorityLevel: "medium", activity: [
    { type: "moved", from: "Inbox", to: "Up Next", time: "1 day ago" },
    { type: "priority", from: "none", to: "medium", time: "3 days ago" },
    { type: "created", time: "5 days ago" },
  ]},
  { id: 5, title: "Record 2-min video guide", project: "tini", column: "up_next", subtasks: null, agent: false, agentStatus: null, notes: "Short walkthrough for new users", agentHint: null, priority: 3, priorityLevel: "low", activity: [
    { type: "moved", from: "Inbox", to: "Up Next", time: "2 days ago" },
    { type: "created", time: "6 days ago" },
  ]},
  { id: 6, title: "Finalize RevenueCat integration", project: "gratu", column: "up_next", subtasks: [
    { id: "6a", title: "Test subscription on TestFlight", done: false },
    { id: "6b", title: "Verify receipt validation", done: false },
  ], agent: false, agentStatus: null, notes: "", agentHint: "Blocks App Store submission", priority: 4, priorityLevel: "high", activity: [
    { type: "moved", from: "In Progress", to: "Up Next", time: "1 day ago" },
    { type: "moved", from: "Inbox", to: "In Progress", time: "5 days ago" },
    { type: "priority", from: "none", to: "high", time: "6 days ago" },
    { type: "created", time: "8 days ago" },
  ]},
  { id: 7, title: "Set up nod.so integration", project: "nod", column: "up_next", subtasks: null, agent: false, agentStatus: null, notes: "", agentHint: null, priority: 5, priorityLevel: "none", activity: [
    { type: "moved", from: "Inbox", to: "Up Next", time: "1 day ago" },
    { type: "created", time: "4 days ago" },
  ]},
  { id: 8, title: "Set up billing settings page", project: "clawdeck", column: "in_progress", subtasks: [
    { id: "8a", title: "Create settings UI", done: true },
    { id: "8b", title: "Wire up API endpoints", done: true },
    { id: "8c", title: "Add plan display component", done: true },
    { id: "8d", title: "Implement upgrade prompt", done: false },
    { id: "8e", title: "Test billing flow end-to-end", done: false },
  ], agent: true, agentStatus: "working", notes: "Agent is building this", agentHint: null, priority: 1, priorityLevel: "high", activity: [
    { type: "agent", action: "completed subtask 3/5", time: "28 min ago" },
    { type: "agent", action: "started working", time: "3 hours ago" },
    { type: "moved", from: "Up Next", to: "In Progress", time: "3 hours ago" },
    { type: "priority", from: "medium", to: "high", time: "2 days ago" },
    { type: "created", time: "7 days ago" },
  ]},
  { id: 9, title: "Add board limit enforcement", project: "clawdeck", column: "in_review", subtasks: [
    { id: "9a", title: "Enforce free tier limits", done: true },
    { id: "9b", title: "Show upgrade prompt", done: true },
  ], agent: true, agentStatus: "done", notes: "Agent completed — needs review", agentHint: null, priority: 1, priorityLevel: "medium", activity: [
    { type: "agent", action: "finished all subtasks", time: "12 min ago" },
    { type: "moved", from: "In Progress", to: "In Review", time: "12 min ago" },
    { type: "agent", action: "started working", time: "1 day ago" },
    { type: "moved", from: "Up Next", to: "In Progress", time: "1 day ago" },
    { type: "created", time: "6 days ago" },
  ]},
  { id: 10, title: "Create upgrade prompt component", project: "clawdeck", column: "done", subtasks: null, agent: true, agentStatus: "done", notes: "", agentHint: null, priority: 1, priorityLevel: "medium", activity: [
    { type: "moved", from: "In Review", to: "Done", time: "1 day ago" },
    { type: "agent", action: "finished", time: "2 days ago" },
    { type: "created", time: "8 days ago" },
  ]},
  { id: 11, title: "Add API rate limiting", project: "clawdeck", column: "done", subtasks: null, agent: true, agentStatus: "done", notes: "", agentHint: null, priority: 2, priorityLevel: "low", activity: [
    { type: "moved", from: "In Review", to: "Done", time: "2 days ago" },
    { type: "created", time: "10 days ago" },
  ]},
  { id: 12, title: "Create API usage tracking table", project: "clawdeck", column: "done", subtasks: null, agent: true, agentStatus: "done", notes: "", agentHint: null, priority: 3, priorityLevel: "none", activity: [
    { type: "moved", from: "In Progress", to: "Done", time: "3 days ago" },
    { type: "created", time: "10 days ago" },
  ]},
  { id: 13, title: "Add subscription fields to User model", project: "clawdeck", column: "done", subtasks: null, agent: true, agentStatus: "done", notes: "", agentHint: null, priority: 4, priorityLevel: "none", activity: [
    { type: "moved", from: "Inbox", to: "Done", time: "5 days ago" },
    { type: "created", time: "10 days ago" },
  ]},
  { id: 14, title: "Add terms of service", project: "clawdeck", column: "done", subtasks: null, agent: false, agentStatus: null, notes: "", agentHint: null, priority: 5, priorityLevel: "none", activity: [
    { type: "moved", from: "Inbox", to: "Done", time: "4 days ago" },
    { type: "created", time: "12 days ago" },
  ]},
  { id: 15, title: "Set up admin emails", project: "clawdeck", column: "done", subtasks: null, agent: false, agentStatus: null, notes: "", agentHint: null, priority: 6, priorityLevel: "none", activity: [
    { type: "moved", from: "Inbox", to: "Done", time: "5 days ago" },
    { type: "created", time: "14 days ago" },
  ]},
];

/* ─── Dropdown Hook ─── */
function useDropdown() {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);
  useEffect(() => {
    const handler = (e) => { if (ref.current && !ref.current.contains(e.target)) setOpen(false); };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);
  return { open, setOpen, ref };
}

/* ─── Board Switcher Dropdown ─── */
function BoardSwitcher({ currentBoard, onSwitch }) {
  const { open, setOpen, ref } = useDropdown();
  return (
    <div ref={ref} style={{ position: "relative" }}>
      <button onClick={() => setOpen(!open)} style={{
        display: "flex", alignItems: "center", gap: 8,
        background: open ? "rgba(255,255,255,0.06)" : "none",
        border: "none", cursor: "pointer", padding: "4px 8px",
        borderRadius: 8, transition: "background 0.15s",
      }}
      onMouseEnter={(e) => { if (!open) e.currentTarget.style.background = "rgba(255,255,255,0.04)"; }}
      onMouseLeave={(e) => { if (!open) e.currentTarget.style.background = open ? "rgba(255,255,255,0.06)" : "none"; }}
      >
        <span style={{ fontSize: 18 }}>{currentBoard.emoji}</span>
        <span style={{ fontSize: 14, fontWeight: 800, color: "#e0e0e0", letterSpacing: "-0.02em" }}>{currentBoard.name}</span>
        <svg width="12" height="12" viewBox="0 0 16 16" fill="none" style={{ opacity: 0.3, marginLeft: 2, transition: "transform 0.2s", transform: open ? "rotate(180deg)" : "rotate(0deg)" }}>
          <path d="M4 6L8 10L12 6" stroke="#888" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </button>
      {open && (
        <div style={{
          position: "absolute", top: "calc(100% + 6px)", left: 0,
          width: 240, padding: 6, borderRadius: 12,
          background: "#1e1e22", border: "1px solid rgba(255,255,255,0.08)",
          boxShadow: "0 20px 50px rgba(0,0,0,0.6)", zIndex: 200,
          animation: "dropIn 0.15s ease both",
        }}>
          <div style={{ padding: "6px 10px 8px", fontSize: 10, fontWeight: 600, color: "#444", textTransform: "uppercase", letterSpacing: "0.06em" }}>Switch board</div>
          {BOARDS.map((board) => (
            <button key={board.id} onClick={() => { onSwitch(board); setOpen(false); }} style={{
              display: "flex", alignItems: "center", gap: 10, width: "100%",
              padding: "9px 10px", borderRadius: 8,
              background: currentBoard.id === board.id ? "rgba(255,255,255,0.06)" : "transparent",
              border: "none", cursor: "pointer", transition: "background 0.12s", textAlign: "left",
            }}
            onMouseEnter={(e) => { if (currentBoard.id !== board.id) e.currentTarget.style.background = "rgba(255,255,255,0.04)"; }}
            onMouseLeave={(e) => { if (currentBoard.id !== board.id) e.currentTarget.style.background = "transparent"; }}
            >
              <span style={{ fontSize: 16, width: 24, textAlign: "center" }}>{board.emoji}</span>
              <span style={{ fontSize: 13, fontWeight: 600, color: currentBoard.id === board.id ? "#e0e0e0" : "#777", flex: 1 }}>{board.name}</span>
              {currentBoard.id === board.id && (
                <svg width="14" height="14" viewBox="0 0 16 16" fill="none"><path d="M3 8.5L6.5 12L13 4" stroke={board.color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
              )}
            </button>
          ))}
          <div style={{ height: 1, background: "rgba(255,255,255,0.06)", margin: "4px 0" }} />
          <button style={{
            display: "flex", alignItems: "center", gap: 10, width: "100%",
            padding: "9px 10px", borderRadius: 8,
            background: "transparent", border: "none", cursor: "pointer", transition: "background 0.12s", textAlign: "left",
          }}
          onMouseEnter={(e) => e.currentTarget.style.background = "rgba(255,255,255,0.04)"}
          onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}
          >
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none" style={{ marginLeft: 4 }}><path d="M8 3V13M3 8H13" stroke="#555" strokeWidth="1.5" strokeLinecap="round"/></svg>
            <span style={{ fontSize: 13, fontWeight: 600, color: "#555" }}>Create new board</span>
          </button>
        </div>
      )}
    </div>
  );
}

/* ─── User Profile Dropdown ─── */
function UserProfileDropdown() {
  const { open, setOpen, ref } = useDropdown();
  const menuItems = [
    { icon: "profile", label: "Profile" },
    { icon: "settings", label: "Settings", shortcut: "⌘," },
    { icon: "agents", label: "Agents" },
    { icon: "billing", label: "Billing" },
  ];
  return (
    <div ref={ref} style={{ position: "relative" }}>
      <button onClick={() => setOpen(!open)} style={{
        width: 30, height: 30, borderRadius: 8,
        background: open ? "rgba(239,68,68,0.12)" : "rgba(255,255,255,0.06)",
        border: open ? "1px solid rgba(239,68,68,0.2)" : "1px solid transparent",
        display: "flex", alignItems: "center", justifyContent: "center",
        fontSize: 13, fontWeight: 700, color: "#e0e0e0", cursor: "pointer", transition: "all 0.15s",
      }}
      onMouseEnter={(e) => { if (!open) e.currentTarget.style.background = "rgba(255,255,255,0.1)"; }}
      onMouseLeave={(e) => { if (!open) e.currentTarget.style.background = open ? "rgba(239,68,68,0.12)" : "rgba(255,255,255,0.06)"; }}
      >M</button>
      {open && (
        <div style={{
          position: "absolute", top: "calc(100% + 6px)", right: 0,
          width: 220, padding: 6, borderRadius: 12,
          background: "#1e1e22", border: "1px solid rgba(255,255,255,0.08)",
          boxShadow: "0 20px 50px rgba(0,0,0,0.6)", zIndex: 200,
          animation: "dropIn 0.15s ease both",
        }}>
          <div style={{ padding: "10px 10px 10px", borderBottom: "1px solid rgba(255,255,255,0.06)", marginBottom: 4 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <div style={{ width: 32, height: 32, borderRadius: 8, background: "linear-gradient(135deg, #ef4444, #f97316)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14, fontWeight: 700, color: "#fff" }}>M</div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 700, color: "#e0e0e0" }}>Max</div>
                <div style={{ fontSize: 11, fontWeight: 500, color: "#555" }}>max@mx.works</div>
              </div>
            </div>
          </div>
          {menuItems.map((item) => (
            <button key={item.label} style={{
              display: "flex", alignItems: "center", gap: 10, width: "100%",
              padding: "8px 10px", borderRadius: 8,
              background: "transparent", border: "none", cursor: "pointer", transition: "background 0.12s", textAlign: "left",
            }}
            onMouseEnter={(e) => e.currentTarget.style.background = "rgba(255,255,255,0.04)"}
            onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}
            >
              <svg width="15" height="15" viewBox="0 0 16 16" fill="none" style={{ opacity: 0.35 }}>
                {item.icon === "profile" && <><circle cx="8" cy="5" r="3" stroke="#888" strokeWidth="1.5"/><path d="M2 14C2 11.5 4.5 10 8 10C11.5 10 14 11.5 14 14" stroke="#888" strokeWidth="1.5" strokeLinecap="round"/></>}
                {item.icon === "settings" && <><circle cx="8" cy="8" r="2.5" stroke="#888" strokeWidth="1.5"/><path d="M8 1V3M8 13V15M1 8H3M13 8H15M3.05 3.05L4.46 4.46M11.54 11.54L12.95 12.95M12.95 3.05L11.54 4.46M4.46 11.54L3.05 12.95" stroke="#888" strokeWidth="1.5" strokeLinecap="round"/></>}
                {item.icon === "agents" && <><rect x="3" y="3" width="10" height="10" rx="2" stroke="#888" strokeWidth="1.5"/><circle cx="6.5" cy="7" r="1" fill="#888"/><circle cx="9.5" cy="7" r="1" fill="#888"/><path d="M6 10C6.5 10.8 7.2 11 8 11C8.8 11 9.5 10.8 10 10" stroke="#888" strokeWidth="1.2" strokeLinecap="round"/></>}
                {item.icon === "billing" && <><rect x="2" y="4" width="12" height="9" rx="2" stroke="#888" strokeWidth="1.5"/><path d="M2 7.5H14" stroke="#888" strokeWidth="1.5"/></>}
              </svg>
              <span style={{ fontSize: 13, fontWeight: 500, color: "#999", flex: 1 }}>{item.label}</span>
              {item.shortcut && <span style={{ fontSize: 10, fontWeight: 500, color: "#333" }}>{item.shortcut}</span>}
            </button>
          ))}
          <div style={{ height: 1, background: "rgba(255,255,255,0.06)", margin: "4px 0" }} />
          <button style={{
            display: "flex", alignItems: "center", gap: 10, width: "100%",
            padding: "8px 10px", borderRadius: 8,
            background: "transparent", border: "none", cursor: "pointer", transition: "background 0.12s", textAlign: "left",
          }}
          onMouseEnter={(e) => e.currentTarget.style.background = "rgba(239,68,68,0.06)"}
          onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}
          >
            <svg width="15" height="15" viewBox="0 0 16 16" fill="none" style={{ opacity: 0.4 }}>
              <path d="M6 2H4C2.9 2 2 2.9 2 4V12C2 13.1 2.9 14 4 14H6M11 11L14 8L11 5M6 8H14" stroke="#ef4444" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            <span style={{ fontSize: 13, fontWeight: 500, color: "#ef4444" }}>Log out</span>
          </button>
        </div>
      )}
    </div>
  );
}

// ─── Command Bar ────────────────────────────────────────
function CommandBar({ tasks, onClose, onSelectTask, onAddCard }) {
  const [query, setQuery] = useState("");
  const [mode, setMode] = useState("search"); // search | agent
  const [agentMessages, setAgentMessages] = useState([]);
  const [agentTyping, setAgentTyping] = useState(false);
  const inputRef = useRef(null);
  const endRef = useRef(null);

  useEffect(() => { inputRef.current?.focus(); }, []);
  useEffect(() => { endRef.current?.scrollIntoView({ behavior: "smooth" }); }, [agentMessages]);

  const filteredTasks = query.trim()
    ? tasks.filter(t => t.title.toLowerCase().includes(query.toLowerCase()))
    : [];

  const quickActions = [
    { id: "add", label: "Add new card", icon: "+", hint: "Create a task" },
    { id: "agent", label: "Ask agent", icon: "🤖", hint: "Get help from AI" },
    { id: "today", label: "What should I focus on?", icon: "☀️", hint: "Agent prioritizes" },
    { id: "breakdown", label: "Break down a task", icon: "📋", hint: "Split into subtasks" },
    { id: "draft", label: "Draft content", icon: "✍️", hint: "Write posts, emails" },
    { id: "recap", label: "Weekly recap", icon: "📊", hint: "Summary of progress" },
  ];

  const handleAction = (actionId) => {
    if (actionId === "add") { onClose(); onAddCard(); return; }
    setMode("agent");
    let prompt = "";
    if (actionId === "agent") { prompt = ""; return; }
    if (actionId === "today") prompt = "What should I focus on today?";
    if (actionId === "breakdown") prompt = "Break down my top priority task";
    if (actionId === "draft") prompt = "Help me draft an announcement post";
    if (actionId === "recap") prompt = "Give me a weekly recap";
    if (prompt) sendAgentMessage(prompt);
  };

  const sendAgentMessage = (text) => {
    setAgentMessages(p => [...p, { type: "user", text }]);
    setAgentTyping(true);

    setTimeout(() => {
      setAgentTyping(false);
      let response = "I can help with that. What specifically would you like me to do?";

      if (text.toLowerCase().includes("focus") || text.toLowerCase().includes("today") || text.toLowerCase().includes("priorit")) {
        response = "Looking at your board, here's what I'd tackle:\n\n1. Review the board limit enforcement card — I've finished it, just needs your eyes\n2. Polar.sh integration — I'm on it but the webhook handler needs your input\n3. RevenueCat for Gratu — this blocks your App Store launch\n\nWant me to move these to In Progress?";
      }
      if (text.toLowerCase().includes("break") || text.toLowerCase().includes("subtask")) {
        response = "I'd break \"Integrate Polar.sh payments\" into:\n\n1. Set up Polar.sh account & products ✅\n2. Implement webhook handler for payment events\n3. Create billing settings page UI\n4. Add subscription status to user model\n5. Test end-to-end payment flow\n\nWant me to add these as subtasks?";
      }
      if (text.toLowerCase().includes("draft") || text.toLowerCase().includes("post") || text.toLowerCase().includes("announce")) {
        response = "Here's a draft for tini.bio:\n\n\"🔗 Built this for founders who hate bloated link-in-bio tools.\n\ntini.bio — dead simple. Beautifully minimal.\n\nNo templates. No analytics dashboards. Just your links.\n\nFree → tini.bio\"\n\nWant me to tweak the tone or make it longer?";
      }
      if (text.toLowerCase().includes("recap") || text.toLowerCase().includes("week") || text.toLowerCase().includes("summary")) {
        response = "This week across your projects:\n\n🦞 ClawDeck — 7 cards completed, billing flow nearly done\n🔗 tini.bio — 2 cards moved forward, AppSumo still in inbox\n🙏 Gratu — RevenueCat blocked, needs your attention\n📬 nod.so — 1 card, pricing research queued\n\nBiggest win: the agent knocked out 5 ClawDeck tasks autonomously.";
      }

      setAgentMessages(p => [...p, { type: "agent", text: response }]);
    }, 1200);
  };

  const handleSubmit = () => {
    if (!query.trim()) return;
    if (mode === "agent") {
      sendAgentMessage(query);
      setQuery("");
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === "Escape") onClose();
    if (e.key === "Enter" && mode === "agent") handleSubmit();
    if (e.key === "Enter" && mode === "search" && filteredTasks.length > 0) {
      onSelectTask(filteredTasks[0].id);
      onClose();
    }
  };

  return (
    <>
      <div onClick={onClose} style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)", zIndex: 300 }} />
      <div style={{
        position: "fixed", top: "15%", left: "50%", transform: "translateX(-50%)",
        width: 520, maxHeight: "65vh",
        background: "#1e1e22", borderRadius: 16,
        border: "1px solid rgba(255,255,255,0.08)",
        boxShadow: "0 32px 80px rgba(0,0,0,0.5)",
        display: "flex", flexDirection: "column",
        zIndex: 301, overflow: "hidden",
        animation: "cmdIn 0.15s ease",
      }}>
        {/* Input */}
        <div style={{
          display: "flex", alignItems: "center", gap: 10,
          padding: "14px 18px",
          borderBottom: "1px solid rgba(255,255,255,0.06)",
        }}>
          {mode === "agent" ? (
            <span style={{ fontSize: 16 }}>🤖</span>
          ) : (
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none" style={{ opacity: 0.3 }}>
              <circle cx="7" cy="7" r="5" stroke="#888" strokeWidth="1.5"/>
              <path d="M11 11L14 14" stroke="#888" strokeWidth="1.5" strokeLinecap="round"/>
            </svg>
          )}
          <input
            ref={inputRef}
            value={query}
            onChange={e => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={mode === "agent" ? "Ask your agent anything..." : "Search cards, ask agent, or take an action..."}
            style={{
              flex: 1, background: "none", border: "none", outline: "none",
              fontSize: 14, fontWeight: 500, color: "#e0e0e0", fontFamily: "inherit",
            }}
          />
          {mode === "agent" && (
            <button onClick={() => { setMode("search"); setQuery(""); setAgentMessages([]); }} style={{
              fontSize: 10, fontWeight: 600, color: "#555", background: "rgba(255,255,255,0.04)",
              border: "1px solid rgba(255,255,255,0.06)", padding: "3px 8px", borderRadius: 5, cursor: "pointer",
            }}>Back</button>
          )}
          <span style={{ fontSize: 10, fontWeight: 600, color: "#333", background: "rgba(255,255,255,0.03)", padding: "3px 7px", borderRadius: 5 }}>esc</span>
        </div>

        {/* Body */}
        <div style={{ flex: 1, overflowY: "auto", padding: "6px 0" }}>

          {/* Agent mode */}
          {mode === "agent" && (
            <div style={{ padding: "8px 16px", display: "flex", flexDirection: "column", gap: 8 }}>
              {agentMessages.length === 0 && (
                <div style={{ padding: "20px 0", textAlign: "center" }}>
                  <div style={{ fontSize: 28, marginBottom: 10 }}>🤖</div>
                  <div style={{ fontSize: 13, fontWeight: 600, color: "#666" }}>Ask me anything about your tasks</div>
                  <div style={{ fontSize: 11, fontWeight: 500, color: "#444", marginTop: 4 }}>I can prioritize, break down tasks, draft content, or recap your week</div>
                  <div style={{ display: "flex", gap: 5, justifyContent: "center", marginTop: 16, flexWrap: "wrap" }}>
                    {["What should I focus on?", "Break down top task", "Draft X post", "Weekly recap"].map(q => (
                      <button key={q} onClick={() => sendAgentMessage(q)} style={{
                        fontSize: 11, fontWeight: 500, padding: "5px 11px", borderRadius: 7,
                        background: "rgba(251,191,36,0.06)", border: "1px solid rgba(251,191,36,0.10)",
                        color: "#999", cursor: "pointer",
                      }}>{q}</button>
                    ))}
                  </div>
                </div>
              )}
              {agentMessages.map((m, i) => (
                <div key={i} style={{
                  alignSelf: m.type === "user" ? "flex-end" : "flex-start",
                  maxWidth: "88%", padding: "9px 13px",
                  borderRadius: m.type === "user" ? "12px 12px 3px 12px" : "12px 12px 12px 3px",
                  background: m.type === "user" ? "rgba(255,255,255,0.08)" : "rgba(251,191,36,0.05)",
                  border: m.type === "user" ? "1px solid rgba(255,255,255,0.08)" : "1px solid rgba(251,191,36,0.08)",
                  color: m.type === "user" ? "#ddd" : "#bbb",
                  fontSize: 12.5, lineHeight: 1.55, whiteSpace: "pre-wrap",
                }}>{m.text}</div>
              ))}
              {agentTyping && (
                <div style={{
                  alignSelf: "flex-start", padding: "9px 13px",
                  borderRadius: "12px 12px 12px 3px",
                  background: "rgba(251,191,36,0.05)", border: "1px solid rgba(251,191,36,0.08)",
                  fontSize: 12.5, color: "#666",
                  display: "flex", alignItems: "center", gap: 6,
                }}>
                  <div style={{ display: "flex", gap: 3 }}>
                    {[0, 1, 2].map(i => (
                      <div key={i} style={{
                        width: 5, height: 5, borderRadius: "50%", background: "#fbbf24",
                        animation: `dotBounce 1s ease ${i * 0.15}s infinite`,
                      }} />
                    ))}
                  </div>
                </div>
              )}
              <div ref={endRef} />
            </div>
          )}

          {/* Search mode */}
          {mode === "search" && (
            <>
              {/* Search results */}
              {query.trim() && filteredTasks.length > 0 && (
                <div style={{ padding: "4px 8px" }}>
                  <div style={{ fontSize: 10, fontWeight: 700, color: "#444", textTransform: "uppercase", letterSpacing: "0.06em", padding: "6px 10px" }}>Cards</div>
                  {filteredTasks.slice(0, 6).map(t => {
                    const p = PROJECTS.find(pr => pr.id === t.project);
                    const col = COLUMNS.find(c => c.id === t.column);
                    return (
                      <button key={t.id} onClick={() => { onSelectTask(t.id); onClose(); }} style={{
                        display: "flex", alignItems: "center", gap: 10, width: "100%",
                        padding: "9px 10px", borderRadius: 8, border: "none",
                        background: "transparent", cursor: "pointer", textAlign: "left",
                        transition: "background 0.1s",
                      }}
                        onMouseEnter={e => { e.currentTarget.style.background = "rgba(255,255,255,0.04)"; }}
                        onMouseLeave={e => { e.currentTarget.style.background = "transparent"; }}
                      >
                        <div style={{ width: 6, height: 6, borderRadius: "50%", background: p?.color || "#555" }} />
                        <span style={{ flex: 1, fontSize: 13, fontWeight: 500, color: "#ccc" }}>{t.title}</span>
                        <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
                          <div style={{ width: 5, height: 5, borderRadius: "50%", background: col?.dot || "#444" }} />
                          <span style={{ fontSize: 10, fontWeight: 500, color: "#444" }}>{col?.label}</span>
                        </div>
                      </button>
                    );
                  })}
                </div>
              )}

              {query.trim() && filteredTasks.length === 0 && (
                <div style={{ padding: "20px 18px", textAlign: "center", fontSize: 12, color: "#444" }}>
                  No cards found for "{query}"
                </div>
              )}

              {/* Quick actions (when no query) */}
              {!query.trim() && (
                <div style={{ padding: "4px 8px" }}>
                  <div style={{ fontSize: 10, fontWeight: 700, color: "#444", textTransform: "uppercase", letterSpacing: "0.06em", padding: "6px 10px" }}>Actions</div>
                  {quickActions.map(a => (
                    <button key={a.id} onClick={() => handleAction(a.id)} style={{
                      display: "flex", alignItems: "center", gap: 10, width: "100%",
                      padding: "9px 10px", borderRadius: 8, border: "none",
                      background: "transparent", cursor: "pointer", textAlign: "left",
                      transition: "background 0.1s",
                    }}
                      onMouseEnter={e => { e.currentTarget.style.background = "rgba(255,255,255,0.04)"; }}
                      onMouseLeave={e => { e.currentTarget.style.background = "transparent"; }}
                    >
                      <div style={{
                        width: 28, height: 28, borderRadius: 7,
                        background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.05)",
                        display: "flex", alignItems: "center", justifyContent: "center",
                        fontSize: 13,
                      }}>{a.icon}</div>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: 13, fontWeight: 600, color: "#ccc" }}>{a.label}</div>
                      </div>
                      <span style={{ fontSize: 10, fontWeight: 500, color: "#333" }}>{a.hint}</span>
                    </button>
                  ))}
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </>
  );
}

// ─── Add Card Modal ─────────────────────────────────────
function AddCardModal({ onClose, onAdd, defaultColumn }) {
  const [title, setTitle] = useState("");
  const [project, setProject] = useState("clawdeck");
  const [column, setColumn] = useState(defaultColumn || "inbox");
  const [notes, setNotes] = useState("");
  const [assignAgent, setAssignAgent] = useState(false);
  const inputRef = useRef(null);

  useEffect(() => { inputRef.current?.focus(); }, []);

  const handleSubmit = () => {
    if (!title.trim()) return;
    onAdd({
      id: Date.now(), title, project, column,
      subtasks: null, agent: assignAgent, agentStatus: assignAgent ? "working" : null,
      notes, agentHint: null, priority: 99,
    });
    onClose();
  };

  const selectedProject = PROJECTS.find(p => p.id === project);

  return (
    <>
      <div onClick={onClose} style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)", zIndex: 300 }} />
      <div style={{
        position: "fixed", top: "18%", left: "50%", transform: "translateX(-50%)",
        width: 460, background: "#1e1e22", borderRadius: 16,
        border: "1px solid rgba(255,255,255,0.08)",
        boxShadow: "0 32px 80px rgba(0,0,0,0.5)",
        zIndex: 301, overflow: "hidden",
        animation: "cmdIn 0.15s ease",
      }}>
        {/* Header */}
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "16px 20px 12px",
        }}>
          <h3 style={{ fontSize: 15, fontWeight: 700, color: "#e0e0e0" }}>New card</h3>
          <button onClick={onClose} style={{ background: "none", border: "none", cursor: "pointer", color: "#444", fontSize: 16 }}>✕</button>
        </div>

        <div style={{ padding: "0 20px 20px", display: "flex", flexDirection: "column", gap: 16 }}>
          {/* Title */}
          <div>
            <input ref={inputRef} value={title} onChange={e => setTitle(e.target.value)}
              onKeyDown={e => { if (e.key === "Enter" && title.trim()) handleSubmit(); if (e.key === "Escape") onClose(); }}
              placeholder="What needs to be done?"
              style={{
                width: "100%", padding: "12px 14px", borderRadius: 10,
                border: "1px solid rgba(255,255,255,0.08)", background: "rgba(255,255,255,0.04)",
                fontSize: 14, fontWeight: 600, color: "#e0e0e0", outline: "none", fontFamily: "inherit",
              }}
            />
          </div>

          {/* Project + Column row */}
          <div style={{ display: "flex", gap: 10 }}>
            {/* Project picker */}
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 10, fontWeight: 700, color: "#444", textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: 6 }}>Project</div>
              <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
                {PROJECTS.map(p => (
                  <button key={p.id} onClick={() => setProject(p.id)} style={{
                    padding: "5px 10px", borderRadius: 7, fontSize: 11, fontWeight: 600,
                    background: project === p.id ? `${p.color}15` : "rgba(255,255,255,0.03)",
                    color: project === p.id ? p.color : "#555",
                    border: project === p.id ? `1px solid ${p.color}25` : "1px solid rgba(255,255,255,0.04)",
                    cursor: "pointer", transition: "all 0.12s",
                    display: "flex", alignItems: "center", gap: 4,
                  }}>{p.emoji} {p.name}</button>
                ))}
              </div>
            </div>
          </div>

          {/* Column picker */}
          <div>
            <div style={{ fontSize: 10, fontWeight: 700, color: "#444", textTransform: "uppercase", letterSpacing: "0.06em", marginBottom: 6 }}>Status</div>
            <div style={{ display: "flex", gap: 4 }}>
              {COLUMNS.filter(c => c.id !== "done").map(col => (
                <button key={col.id} onClick={() => setColumn(col.id)} style={{
                  padding: "5px 10px", borderRadius: 7, fontSize: 11, fontWeight: 600,
                  background: column === col.id ? "rgba(255,255,255,0.08)" : "rgba(255,255,255,0.03)",
                  color: column === col.id ? "#ccc" : "#555",
                  border: column === col.id ? "1px solid rgba(255,255,255,0.10)" : "1px solid rgba(255,255,255,0.04)",
                  cursor: "pointer", transition: "all 0.12s",
                  display: "flex", alignItems: "center", gap: 5,
                }}>
                  <div style={{ width: 5, height: 5, borderRadius: "50%", background: col.dot, opacity: column === col.id ? 1 : 0.3 }} />
                  {col.label}
                </button>
              ))}
            </div>
          </div>

          {/* Notes (collapsed by default) */}
          <div>
            <textarea value={notes} onChange={e => setNotes(e.target.value)}
              placeholder="Notes (optional)"
              style={{
                width: "100%", minHeight: 56, padding: 12, borderRadius: 10,
                border: "1px solid rgba(255,255,255,0.06)", background: "rgba(255,255,255,0.03)",
                fontSize: 12, color: "#999", resize: "vertical", outline: "none", lineHeight: 1.5,
                fontFamily: "inherit",
              }}
            />
          </div>

          {/* Agent toggle + Submit */}
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <button onClick={() => setAssignAgent(!assignAgent)} style={{
              display: "flex", alignItems: "center", gap: 7,
              padding: "7px 12px", borderRadius: 8,
              background: assignAgent ? "rgba(251,191,36,0.08)" : "rgba(255,255,255,0.03)",
              border: assignAgent ? "1px solid rgba(251,191,36,0.15)" : "1px solid rgba(255,255,255,0.05)",
              cursor: "pointer", transition: "all 0.12s",
            }}>
              <span style={{ fontSize: 13 }}>🤖</span>
              <span style={{ fontSize: 11, fontWeight: 600, color: assignAgent ? "#fbbf24" : "#555" }}>
                {assignAgent ? "Agent assigned" : "Assign to agent"}
              </span>
            </button>

            <button onClick={handleSubmit} disabled={!title.trim()} style={{
              padding: "9px 20px", borderRadius: 9,
              background: title.trim() ? (selectedProject?.color || "#ef4444") : "rgba(255,255,255,0.04)",
              border: "none", cursor: title.trim() ? "pointer" : "default",
              fontSize: 13, fontWeight: 700,
              color: title.trim() ? "#fff" : "#333",
              transition: "all 0.15s",
              opacity: title.trim() ? 1 : 0.5,
            }}>Create card</button>
          </div>
        </div>
      </div>
    </>
  );
}

// ─── Board Card ──────────────────────────────────────────
function BoardCard({ task, onSelect, isSelected, onDragStart }) {
  const project = PROJECTS.find(p => p.id === task.project);
  const doneCount = task.subtasks ? task.subtasks.filter(s => s.done).length : 0;
  const totalCount = task.subtasks ? task.subtasks.length : 0;
  const isDone = task.column === "done";

  return (
    <div draggable onDragStart={(e) => { e.dataTransfer.effectAllowed = "move"; onDragStart(task.id); }}
      onClick={() => onSelect(task.id)}
      style={{
        padding: "12px 14px", background: isSelected ? "rgba(255,255,255,0.07)" : "rgba(255,255,255,0.035)",
        borderRadius: 10, border: isSelected ? `1px solid ${project?.color || "#555"}40` : "1px solid rgba(255,255,255,0.05)",
        cursor: "grab", transition: "all 0.15s ease", opacity: isDone ? 0.5 : 1,
        position: "relative", overflow: "hidden",
      }}
    >

      <div style={{ fontSize: 13, fontWeight: 600, color: isDone ? "#555" : "#ddd", lineHeight: 1.35, marginBottom: 7 }}>{task.title}</div>
      <div style={{ display: "flex", alignItems: "center", gap: 5, flexWrap: "wrap" }}>
        {totalCount > 0 && (
          <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
            <span style={{ fontSize: 10, fontWeight: 500, color: "#444" }}>☐ {doneCount}/{totalCount}</span>
            <div style={{ width: 32, height: 3, borderRadius: 2, background: "rgba(255,255,255,0.06)", overflow: "hidden" }}>
              <div style={{ height: "100%", borderRadius: 2, background: project?.color || "#555", width: `${totalCount > 0 ? (doneCount / totalCount) * 100 : 0}%`, opacity: 0.7 }} />
            </div>
          </div>
        )}
        {task.notes && <span style={{ fontSize: 9, color: "#444" }}>💬</span>}
      </div>
      {task.agent && (
        <div style={{
          display: "flex", alignItems: "center", gap: 4, marginTop: 8, padding: "3px 7px", borderRadius: 6,
          background: task.agentStatus === "done" ? "rgba(52,211,153,0.08)" : "rgba(251,191,36,0.08)",
          border: `1px solid ${task.agentStatus === "done" ? "rgba(52,211,153,0.10)" : "rgba(251,191,36,0.10)"}`,
          width: "fit-content",
        }}>
          <span style={{ fontSize: 9 }}>🤖</span>
          <span style={{ fontSize: 9, fontWeight: 600, color: task.agentStatus === "done" ? "#34d399" : "#fbbf24" }}>
            {task.agentStatus === "done" ? "Review" : "Working"}
          </span>
          {task.agentStatus === "working" && <div style={{ width: 4, height: 4, borderRadius: "50%", background: "#fbbf24", animation: "pulse 1.5s ease infinite" }} />}
        </div>
      )}
      {task.agentHint && !isDone && (
        <div style={{
          marginTop: 8, padding: "5px 8px", borderRadius: 6,
          background: "rgba(251,191,36,0.05)", border: "1px solid rgba(251,191,36,0.08)",
          display: "flex", alignItems: "center", gap: 5,
        }}>
          <span style={{ fontSize: 9 }}>💡</span>
          <span style={{ fontSize: 10, fontWeight: 500, color: "#888", fontStyle: "italic", lineHeight: 1.3 }}>{task.agentHint}</span>
        </div>
      )}
    </div>
  );
}

// ─── Detail Panel ────────────────────────────────────────
function DetailPanel({ task, onClose, onToggleSubtask, onUpdateNotes, onMoveColumn, onSetPriority, onToggleAgent }) {
  const project = PROJECTS.find(p => p.id === task.project);
  const [notes, setNotes] = useState(task.notes);
  const [statusOpen, setStatusOpen] = useState(false);
  const statusRef = useRef(null);
  const c = project?.color || "#888";
  const currentPriority = PRIORITY_LEVELS.find(p => p.id === task.priorityLevel) || PRIORITY_LEVELS[0];
  const currentCol = COLUMNS.find(col => col.id === task.column) || COLUMNS[0];
  useEffect(() => { setNotes(task.notes); }, [task.id, task.notes]);
  useEffect(() => {
    const handler = (e) => { if (statusRef.current && !statusRef.current.contains(e.target)) setStatusOpen(false); };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const getActivityIcon = (item) => {
    if (item.type === "created") return { bg: "rgba(96,165,250,0.12)", border: "rgba(96,165,250,0.2)", color: "#60a5fa", symbol: "+" };
    if (item.type === "moved") return { bg: "rgba(167,139,250,0.12)", border: "rgba(167,139,250,0.2)", color: "#a78bfa", symbol: "→" };
    if (item.type === "priority") return { bg: "rgba(52,211,153,0.12)", border: "rgba(52,211,153,0.2)", color: "#34d399", symbol: "!" };
    if (item.type === "agent") return { bg: "rgba(251,191,36,0.12)", border: "rgba(251,191,36,0.2)", color: "#fbbf24", symbol: "🤖" };
    return { bg: "rgba(255,255,255,0.06)", border: "rgba(255,255,255,0.08)", color: "#666", symbol: "•" };
  };

  const getActivityText = (item) => {
    if (item.type === "created") return "Created";
    if (item.type === "moved") return `Moved from ${item.from} to ${item.to}`;
    if (item.type === "priority") return `Changed priority from ${item.from} to ${item.to}`;
    if (item.type === "agent") return `Agent ${item.action}`;
    return "";
  };

  return (
    <>
      <div onClick={onClose} style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.4)", zIndex: 200 }} />
      <div style={{
        position: "fixed", top: 0, right: 0, width: 400, height: "100vh",
        background: "#1a1a1e", borderLeft: "1px solid rgba(255,255,255,0.06)",
        display: "flex", flexDirection: "column", zIndex: 201, animation: "slideIn 0.2s ease", overflow: "hidden",
      }}>
        {/* Header — status pill + close */}
        <div style={{ padding: "16px 20px", borderBottom: "1px solid rgba(255,255,255,0.05)", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div style={{
            fontSize: 11, fontWeight: 700, color: "#ccc",
            background: "rgba(255,255,255,0.06)", padding: "4px 12px", borderRadius: 6,
            border: "1px solid rgba(255,255,255,0.08)",
          }}>
            {COLUMNS.find(col => col.id === task.column)?.label || "Inbox"}
          </div>
          <button onClick={onClose} style={{ background: "none", border: "none", cursor: "pointer", color: "#444", fontSize: 18 }}>✕</button>
        </div>

        <div style={{ flex: 1, overflowY: "auto", padding: "20px 20px 32px", display: "flex", flexDirection: "column", gap: 24 }}>
          {/* Title */}
          <h2 style={{ fontSize: 20, fontWeight: 800, color: "#f0f0f0", letterSpacing: "-0.02em", lineHeight: 1.3 }}>{task.title}</h2>

          {/* Notes */}
          <div>
            <textarea value={notes} onChange={(e) => { setNotes(e.target.value); onUpdateNotes(task.id, e.target.value); }}
              placeholder="Add notes..." style={{
                width: "100%", minHeight: 72, padding: 12, borderRadius: 10,
                border: "1px solid rgba(255,255,255,0.06)", background: "rgba(255,255,255,0.03)",
                fontSize: 13, color: "#bbb", resize: "vertical", outline: "none", lineHeight: 1.6, fontFamily: "inherit",
              }} />
          </div>

          {/* Details section */}
          <div>
            <div style={{ fontSize: 13, fontWeight: 700, color: "#e0e0e0", marginBottom: 14 }}>Details</div>

            {/* Status row */}
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
              <span style={{ fontSize: 12, fontWeight: 500, color: "#888" }}>Status</span>
              <div ref={statusRef} style={{ position: "relative" }}>
                <button onClick={() => setStatusOpen(!statusOpen)} style={{
                  display: "flex", alignItems: "center", gap: 7,
                  padding: "5px 12px", borderRadius: 8, cursor: "pointer",
                  background: statusOpen ? "rgba(255,255,255,0.08)" : "rgba(255,255,255,0.04)",
                  border: statusOpen ? "1px solid rgba(255,255,255,0.12)" : "1px solid rgba(255,255,255,0.06)",
                  transition: "all 0.12s",
                }}>
                  <div style={{ width: 6, height: 6, borderRadius: "50%", background: currentCol.dot }} />
                  <span style={{ fontSize: 12, fontWeight: 600, color: "#ccc" }}>{currentCol.label}</span>
                  <svg width="10" height="10" viewBox="0 0 16 16" fill="none" style={{ opacity: 0.3, transition: "transform 0.15s", transform: statusOpen ? "rotate(180deg)" : "rotate(0deg)" }}>
                    <path d="M4 6L8 10L12 6" stroke="#888" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </button>
                {statusOpen && (
                  <div style={{
                    position: "absolute", top: "calc(100% + 4px)", right: 0,
                    width: 180, padding: 4, borderRadius: 10,
                    background: "#222226", border: "1px solid rgba(255,255,255,0.08)",
                    boxShadow: "0 12px 40px rgba(0,0,0,0.5)", zIndex: 10,
                    animation: "dropIn 0.12s ease both",
                  }}>
                    {COLUMNS.map(col => (
                      <button key={col.id} onClick={() => { onMoveColumn(task.id, col.id); setStatusOpen(false); }} style={{
                        display: "flex", alignItems: "center", gap: 9, width: "100%",
                        padding: "8px 10px", borderRadius: 7,
                        background: task.column === col.id ? "rgba(255,255,255,0.06)" : "transparent",
                        border: "none", cursor: "pointer", transition: "background 0.1s", textAlign: "left",
                      }}
                      onMouseEnter={(e) => { if (task.column !== col.id) e.currentTarget.style.background = "rgba(255,255,255,0.04)"; }}
                      onMouseLeave={(e) => { if (task.column !== col.id) e.currentTarget.style.background = "transparent"; }}
                      >
                        <div style={{ width: 7, height: 7, borderRadius: "50%", background: col.dot }} />
                        <span style={{ fontSize: 12, fontWeight: 600, color: task.column === col.id ? "#e0e0e0" : "#888", flex: 1 }}>{col.label}</span>
                        {task.column === col.id && (
                          <svg width="12" height="12" viewBox="0 0 16 16" fill="none"><path d="M3 8.5L6.5 12L13 4" stroke={col.dot} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
                        )}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Priority row */}
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
              <span style={{ fontSize: 12, fontWeight: 500, color: "#888" }}>Priority</span>
              <div style={{ display: "flex", gap: 6 }}>
                {PRIORITY_LEVELS.map(p => (
                  <button key={p.id} onClick={() => onSetPriority(task.id, p.id)} style={{
                    width: 32, height: 32, borderRadius: 8, cursor: "pointer",
                    background: task.priorityLevel === p.id ? `${p.color}18` : "rgba(255,255,255,0.03)",
                    border: task.priorityLevel === p.id ? `1px solid ${p.color}35` : "1px solid rgba(255,255,255,0.06)",
                    display: "flex", alignItems: "center", justifyContent: "center", gap: 2,
                    transition: "all 0.12s",
                  }}>
                    {Array.from({ length: p.dots }).map((_, i) => (
                      <div key={i} style={{
                        width: 5, height: 5, borderRadius: "50%",
                        background: task.priorityLevel === p.id ? p.color : "#444",
                      }} />
                    ))}
                  </button>
                ))}
              </div>
            </div>

            {/* Agent row */}
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <span style={{ fontSize: 12, fontWeight: 500, color: "#888" }}>Agent</span>
              <button onClick={() => onToggleAgent(task.id)} style={{
                display: "flex", alignItems: "center", gap: 5,
                padding: "4px 10px", borderRadius: 7, cursor: "pointer",
                background: task.agent ? "rgba(251,191,36,0.1)" : "rgba(255,255,255,0.03)",
                border: task.agent ? "1px solid rgba(251,191,36,0.2)" : "1px solid rgba(255,255,255,0.06)",
                transition: "all 0.12s",
              }}>
                <span style={{ fontSize: 11 }}>🤖</span>
                <span style={{ fontSize: 11, fontWeight: 600, color: task.agent ? "#fbbf24" : "#555" }}>
                  {task.agent ? "Assigned" : "Assign"}
                </span>
              </button>
            </div>
          </div>

          {/* Agent status banner */}
          {task.agent && (
            <div style={{
              padding: "12px 14px", borderRadius: 10,
              background: task.agentStatus === "done" ? "rgba(52,211,153,0.05)" : "rgba(251,191,36,0.05)",
              border: `1px solid ${task.agentStatus === "done" ? "rgba(52,211,153,0.10)" : "rgba(251,191,36,0.10)"}`,
              display: "flex", alignItems: "center", gap: 9,
            }}>
              <span style={{ fontSize: 16 }}>🤖</span>
              <div>
                <div style={{ fontSize: 12, fontWeight: 600, color: task.agentStatus === "done" ? "#34d399" : "#fbbf24" }}>
                  {task.agentStatus === "done" ? "Agent finished — needs review" : "Agent is working on this"}
                </div>
                <div style={{ fontSize: 11, fontWeight: 500, color: "#444", marginTop: 2 }}>
                  {task.agentStatus === "done" ? "Review changes before moving to Done" : "Check back soon for updates"}
                </div>
              </div>
            </div>
          )}

          {/* Subtasks */}
          {task.subtasks && task.subtasks.length > 0 && (
            <div>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 8 }}>
                <div style={{ fontSize: 10, fontWeight: 700, color: "#444", textTransform: "uppercase", letterSpacing: "0.06em" }}>Subtasks</div>
                <span style={{ fontSize: 10, fontWeight: 600, color: "#444" }}>{task.subtasks.filter(s => s.done).length}/{task.subtasks.length}</span>
              </div>
              <div style={{ height: 3, borderRadius: 2, background: "rgba(255,255,255,0.05)", marginBottom: 10, overflow: "hidden" }}>
                <div style={{ height: "100%", borderRadius: 2, background: c, width: `${(task.subtasks.filter(s => s.done).length / task.subtasks.length) * 100}%`, opacity: 0.8 }} />
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
                {task.subtasks.map(st => (
                  <div key={st.id} onClick={() => onToggleSubtask(task.id, st.id)} style={{
                    display: "flex", alignItems: "center", gap: 10, padding: "8px 10px", borderRadius: 8,
                    background: "rgba(255,255,255,0.03)", border: "1px solid rgba(255,255,255,0.04)", cursor: "pointer",
                  }}>
                    <div style={{
                      width: 16, height: 16, borderRadius: 4,
                      border: st.done ? "none" : "1.5px solid rgba(255,255,255,0.15)",
                      background: st.done ? c : "transparent",
                      display: "flex", alignItems: "center", justifyContent: "center",
                    }}>{st.done && <svg width="9" height="9" viewBox="0 0 16 16" fill="none"><path d="M3 8.5L6.5 12L13 4" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/></svg>}</div>
                    <span style={{ fontSize: 12.5, fontWeight: 500, color: st.done ? "#444" : "#bbb", textDecoration: st.done ? "line-through" : "none" }}>{st.title}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Suggestion hint */}
          {task.agentHint && (
            <div style={{
              padding: "12px 14px", borderRadius: 10, background: "rgba(251,191,36,0.04)", border: "1px solid rgba(251,191,36,0.08)",
              display: "flex", alignItems: "flex-start", gap: 9,
            }}>
              <span style={{ fontSize: 14, marginTop: 1 }}>💡</span>
              <div>
                <div style={{ fontSize: 12, fontWeight: 600, color: "#fbbf24", marginBottom: 2 }}>Suggestion</div>
                <div style={{ fontSize: 12, fontWeight: 500, color: "#888", lineHeight: 1.4 }}>{task.agentHint}</div>
              </div>
            </div>
          )}

          {/* Activity Feed */}
          {task.activity && task.activity.length > 0 && (
            <div>
              <div style={{ fontSize: 13, fontWeight: 700, color: "#e0e0e0", marginBottom: 14 }}>Activity</div>
              <div style={{ display: "flex", flexDirection: "column", gap: 0, position: "relative" }}>
                {/* Vertical line */}
                <div style={{
                  position: "absolute", left: 13, top: 14, bottom: 14, width: 1,
                  background: "rgba(255,255,255,0.04)",
                }} />
                {task.activity.map((item, i) => {
                  const icon = getActivityIcon(item);
                  return (
                    <div key={i} style={{
                      display: "flex", alignItems: "flex-start", gap: 10, padding: "8px 0",
                      position: "relative",
                    }}>
                      <div style={{
                        width: 26, height: 26, minWidth: 26, borderRadius: "50%",
                        background: icon.bg, border: `1px solid ${icon.border}`,
                        display: "flex", alignItems: "center", justifyContent: "center",
                        fontSize: item.type === "agent" ? 11 : 12, fontWeight: 700, color: icon.color,
                        zIndex: 1,
                      }}>
                        {item.type === "agent" ? "🤖" : icon.symbol}
                      </div>
                      <div style={{ flex: 1, paddingTop: 2 }}>
                        <div style={{ fontSize: 12, fontWeight: 500, color: "#999", lineHeight: 1.4 }}>
                          {getActivityText(item)}
                        </div>
                        <div style={{ fontSize: 10, fontWeight: 500, color: "#333", marginTop: 2 }}>
                          {item.time}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      </div>
    </>
  );
}

// ─── Main ────────────────────────────────────────────────
export default function ClawDeckBoard() {
  const [tasks, setTasks] = useState(INIT_TASKS);
  const [selectedId, setSelectedId] = useState(null);
  const [dragId, setDragId] = useState(null);
  const [dragOverCol, setDragOverCol] = useState(null);
  const [activeNav, setActiveNav] = useState("boards");
  const [showCmd, setShowCmd] = useState(false);
  const [showAddCard, setShowAddCard] = useState(false);
  const [addCardColumn, setAddCardColumn] = useState(null);
  const [currentBoard, setCurrentBoard] = useState(BOARDS[0]);

  useEffect(() => {
    const handler = (e) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) { e.preventDefault(); setShowCmd(s => !s); }
      if (e.key === "Escape") { setSelectedId(null); setShowCmd(false); setShowAddCard(false); }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []);

  const moveColumn = (id, col) => setTasks(p => p.map(t => t.id === id ? { ...t, column: col } : t));
  const toggleSub = (tid, sid) => setTasks(p => p.map(t => t.id === tid ? { ...t, subtasks: t.subtasks.map(s => s.id === sid ? { ...s, done: !s.done } : s) } : t));
  const updateNotes = (id, n) => setTasks(p => p.map(t => t.id === id ? { ...t, notes: n } : t));
  const addTask = (task) => setTasks(p => [...p, task]);
  const setPriority = (id, level) => setTasks(p => p.map(t => t.id === id ? { ...t, priorityLevel: level } : t));
  const toggleAgent = (id) => setTasks(p => p.map(t => t.id === id ? { ...t, agent: !t.agent, agentStatus: !t.agent ? "working" : null } : t));

  const onDrop = (colId) => {
    if (dragId !== null) moveColumn(dragId, colId);
    setDragId(null); setDragOverCol(null);
  };

  const selectedTask = tasks.find(t => t.id === selectedId);

  return (
    <div style={{ height: "100vh", display: "flex", flexDirection: "column", background: "#161619", color: "#e0e0e0", fontFamily: "'Plus Jakarta Sans', system-ui, sans-serif", overflow: "hidden" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
        * { box-sizing: border-box; margin: 0; padding: 0; }
        ::selection { background: #fbbf24; color: #161619; }
        @keyframes fadeUp { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes slideIn { from { opacity: 0; transform: translateX(16px); } to { opacity: 1; transform: translateX(0); } }
        @keyframes dropIn { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes cmdIn { from { opacity: 0; transform: translateX(-50%) scale(0.96); } to { opacity: 1; transform: translateX(-50%) scale(1); } }
        @keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: 0.25; } }
        @keyframes dotBounce { 0%,100% { transform: translateY(0); opacity: 0.3; } 50% { transform: translateY(-3px); opacity: 1; } }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.05); border-radius: 10px; }
      `}</style>

      {/* Top Nav */}
      <nav style={{
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "0 24px", height: 52, minHeight: 52,
        borderBottom: "1px solid rgba(255,255,255,0.06)", background: "#161619",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
          <BoardSwitcher currentBoard={currentBoard} onSwitch={setCurrentBoard} />
          <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
            {["home", "boards"].map(id => (
              <button key={id} onClick={() => setActiveNav(id)} style={{
                fontSize: 13, fontWeight: 600,
                color: activeNav === id ? "#e0e0e0" : "#555",
                background: activeNav === id ? "rgba(255,255,255,0.06)" : "transparent",
                border: "none", cursor: "pointer", padding: "6px 14px", borderRadius: 8,
                transition: "all 0.15s", textTransform: "capitalize",
              }}>{id}</button>
            ))}
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <button onClick={() => setShowCmd(true)} style={{ fontSize: 12, fontWeight: 600, color: "#888", background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.06)", padding: "5px 12px", borderRadius: 8, cursor: "pointer", display: "flex", alignItems: "center", gap: 5 }}>
            <span style={{ fontSize: 11, opacity: 0.5 }}>⌘</span>K
          </button>
          <button onClick={() => { setShowAddCard(true); setAddCardColumn("inbox"); }} style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, fontWeight: 600, color: "#888", background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.06)", padding: "5px 12px", borderRadius: 8, cursor: "pointer" }}>
            <svg width="14" height="14" viewBox="0 0 16 16" fill="none"><path d="M14 8H2M8 2V14" stroke="#888" strokeWidth="1.5" strokeLinecap="round"/></svg>Add card
          </button>
          <UserProfileDropdown />
        </div>
      </nav>

      {/* Columns */}
      <div style={{ flex: 1, display: "flex", padding: "12px 16px 16px", gap: 10, overflow: "hidden" }}>
        {COLUMNS.map(col => {
          const colTasks = tasks.filter(t => t.column === col.id).sort((a, b) => a.priority - b.priority);
          const isDragOver = dragOverCol === col.id;

          return (
            <div key={col.id}
              onDragOver={(e) => { e.preventDefault(); setDragOverCol(col.id); }}
              onDragLeave={() => setDragOverCol(null)}
              onDrop={() => onDrop(col.id)}
              style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column", height: "100%", overflow: "hidden" }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "6px 8px 10px" }}>
                <div style={{ width: 7, height: 7, borderRadius: "50%", background: col.dot }} />
                <span style={{ fontSize: 13, fontWeight: 700, color: "#bbb" }}>{col.label}</span>
                <span style={{ fontSize: 11, fontWeight: 600, color: "#444", background: "rgba(255,255,255,0.04)", padding: "0 7px", borderRadius: 5, lineHeight: "20px" }}>{colTasks.length}</span>
              </div>
              <div style={{
                flex: 1, borderRadius: 10, padding: 6,
                background: isDragOver ? "rgba(255,255,255,0.03)" : "rgba(255,255,255,0.01)",
                border: isDragOver ? "2px dashed rgba(255,255,255,0.08)" : "2px solid transparent",
                overflowY: "auto", transition: "all 0.12s",
                display: "flex", flexDirection: "column", gap: 5,
              }}>
                {colTasks.map(task => (
                  <BoardCard key={task.id} task={task} onSelect={setSelectedId} isSelected={selectedId === task.id} onDragStart={setDragId} />
                ))}
                <button onClick={() => { setShowAddCard(true); setAddCardColumn(col.id); }} style={{
                  display: "flex", alignItems: "center", gap: 6, padding: "8px 10px", borderRadius: 8,
                  background: "transparent", border: "none", cursor: "pointer", color: "#333",
                  fontSize: 12, fontWeight: 500, marginTop: 2,
                }}
                  onMouseEnter={(e) => { e.currentTarget.style.color = "#666"; }}
                  onMouseLeave={(e) => { e.currentTarget.style.color = "#333"; }}
                >
                  <svg width="12" height="12" viewBox="0 0 16 16" fill="none"><path d="M14 8H2M8 2V14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/></svg>
                  Add a card
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Detail Panel */}
      {selectedTask && (
        <DetailPanel task={selectedTask} onClose={() => setSelectedId(null)} onToggleSubtask={toggleSub} onUpdateNotes={updateNotes} onMoveColumn={moveColumn} onSetPriority={setPriority} onToggleAgent={toggleAgent} />
      )}

      {/* Command Bar */}
      {showCmd && (
        <CommandBar tasks={tasks} onClose={() => setShowCmd(false)} onSelectTask={(id) => { setSelectedId(id); }} onAddCard={() => { setShowAddCard(true); setAddCardColumn("inbox"); }} />
      )}

      {/* Add Card Modal */}
      {showAddCard && (
        <AddCardModal onClose={() => setShowAddCard(false)} onAdd={addTask} defaultColumn={addCardColumn || "inbox"} />
      )}
    </div>
  );
}
