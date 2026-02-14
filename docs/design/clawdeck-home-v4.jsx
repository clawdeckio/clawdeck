import { useState, useEffect, useRef } from "react";

const PROJECTS = [
  { id: "clawdeck", name: "ClawDeck Cloud", emoji: "🦞", color: "#ef4444" },
  { id: "tini", name: "tini.bio", emoji: "🔗", color: "#34d399" },
  { id: "gratu", name: "Gratu", emoji: "🙏", color: "#fbbf24" },
  { id: "nod", name: "nod.so", emoji: "📬", color: "#60a5fa" },
  { id: "mx", name: "mx.works", emoji: "⚡", color: "#a78bfa" },
];

const BOARDS = [
  { id: "clawdeck-cloud", name: "ClawDeck Cloud", emoji: "🦞", color: "#ef4444" },
  { id: "personal", name: "Personal", emoji: "🏠", color: "#60a5fa" },
  { id: "mx-works", name: "mx.works", emoji: "⚡", color: "#a78bfa" },
  { id: "client-projects", name: "Client Projects", emoji: "💼", color: "#34d399" },
];

const TODAY_TASKS = [
  { id: 1, title: "Integrate Polar.sh payments", project: "clawdeck", time: "Morning", subtasks: { done: 1, total: 3 }, agent: true, agentStatus: "working" },
  { id: 2, title: "Record 2-min video guide", project: "tini", time: "11 AM", subtasks: null, agent: false, agentStatus: null },
  { id: 3, title: "Finalize RevenueCat integration", project: "gratu", time: "Afternoon", subtasks: { done: 0, total: 2 }, agent: false, agentStatus: null },
  { id: 4, title: "Create sample profiles for businesses", project: "tini", time: "", subtasks: null, agent: false, agentStatus: null },
  { id: 5, title: "Set up billing settings page", project: "clawdeck", time: "", subtasks: { done: 4, total: 5 }, agent: true, agentStatus: "done" },
];

const AGENT_UPDATES = [
  { id: 1, text: "Billing settings page — 4/5 subtasks done, waiting on review", time: "12 min ago" },
  { id: 2, text: "Polar.sh integration — working on webhook handler", time: "28 min ago" },
];

const NUDGES = [
  { id: 1, text: "\"Make a CRM\" has been deferred 3 times. Commit or drop?", action: "View card" },
  { id: 2, text: "\"X announcement post\" — want me to draft this?", action: "Draft it" },
];

const WEEK_DATA = [
  { day: "Mon", completed: 5, agent: 2, total: 7 },
  { day: "Tue", completed: 3, agent: 4, total: 7 },
  { day: "Wed", completed: 6, agent: 1, total: 7 },
  { day: "Thu", completed: 2, agent: 3, total: 5 },
  { day: "Fri", completed: 4, agent: 2, total: 6 },
  { day: "Sat", completed: 1, agent: 0, total: 1 },
  { day: "Sun", completed: 0, agent: 0, total: 0 },
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
      <button
        onClick={() => setOpen(!open)}
        style={{
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
          background: "#161619", border: "1px solid rgba(255,255,255,0.08)",
          boxShadow: "0 20px 50px rgba(0,0,0,0.6)", zIndex: 200,
          animation: "dropIn 0.15s ease both",
        }}>
          <div style={{ padding: "6px 10px 8px", fontSize: 10, fontWeight: 600, color: "#444", textTransform: "uppercase", letterSpacing: "0.06em" }}>
            Switch board
          </div>
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
          background: "#161619", border: "1px solid rgba(255,255,255,0.08)",
          boxShadow: "0 20px 50px rgba(0,0,0,0.6)", zIndex: 200,
          animation: "dropIn 0.15s ease both",
        }}>
          <div style={{ padding: "10px 10px 10px", borderBottom: "1px solid rgba(255,255,255,0.06)", marginBottom: 4 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <div style={{
                width: 32, height: 32, borderRadius: 8,
                background: "linear-gradient(135deg, #ef4444, #f97316)",
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: 14, fontWeight: 700, color: "#fff",
              }}>M</div>
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

/* ─── Weekly Activity Chart ─── */
function WeeklyActivity() {
  const maxVal = Math.max(...WEEK_DATA.map(d => d.total), 1);
  const totalCompleted = WEEK_DATA.reduce((s, d) => s + d.completed, 0);
  const totalAgent = WEEK_DATA.reduce((s, d) => s + d.agent, 0);
  const todayIndex = new Date().getDay();
  const todayIdx = todayIndex === 0 ? 6 : todayIndex - 1;

  return (
    <div style={{
      padding: "18px 20px", borderRadius: 14,
      background: "rgba(255,255,255,0.025)", border: "1px solid rgba(255,255,255,0.05)",
      marginBottom: 32, animation: "fadeUp 0.35s ease 0.48s both",
    }}>
      {/* Header */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20 }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: "#444", textTransform: "uppercase", letterSpacing: "0.06em" }}>This week</div>
        <div style={{ display: "flex", gap: 14 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 5 }}>
            <div style={{ width: 8, height: 8, borderRadius: 2, background: "#ef4444" }} />
            <span style={{ fontSize: 10, fontWeight: 500, color: "#555" }}>You ({totalCompleted})</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 5 }}>
            <div style={{ width: 8, height: 8, borderRadius: 2, background: "#fbbf24" }} />
            <span style={{ fontSize: 10, fontWeight: 500, color: "#555" }}>Agent ({totalAgent})</span>
          </div>
        </div>
      </div>

      {/* Stacked Bar Chart */}
      <div style={{ display: "flex", alignItems: "flex-end", gap: 6, height: 90, marginBottom: 8 }}>
        {WEEK_DATA.map((d, i) => {
          const completedH = maxVal > 0 ? (d.completed / maxVal) * 72 : 0;
          const agentH = maxVal > 0 ? (d.agent / maxVal) * 72 : 0;
          const isToday = i === todayIdx;
          return (
            <div key={d.day} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", height: "100%", justifyContent: "flex-end" }}>
              {d.total > 0 && (
                <div style={{ fontSize: 9, fontWeight: 700, color: isToday ? "#ddd" : "#333", marginBottom: 4 }}>{d.total}</div>
              )}
              <div style={{ display: "flex", flexDirection: "column", gap: 1, width: "100%", maxWidth: 42 }}>
                {agentH > 0 && (
                  <div style={{
                    height: agentH, borderRadius: completedH > 0 ? "5px 5px 0 0" : 5,
                    background: isToday ? "#fbbf24" : "rgba(251,191,36,0.2)",
                    transition: "height 0.5s cubic-bezier(0.34, 1.56, 0.64, 1)",
                  }} />
                )}
                {completedH > 0 && (
                  <div style={{
                    height: completedH, borderRadius: agentH > 0 ? "0 0 5px 5px" : 5,
                    background: isToday ? "#ef4444" : "rgba(239,68,68,0.2)",
                    transition: "height 0.5s cubic-bezier(0.34, 1.56, 0.64, 1)",
                  }} />
                )}
                {d.total === 0 && (
                  <div style={{ height: 3, borderRadius: 4, background: "rgba(255,255,255,0.04)", width: "100%" }} />
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Day Labels */}
      <div style={{ display: "flex", gap: 6 }}>
        {WEEK_DATA.map((d, i) => (
          <div key={d.day} style={{
            flex: 1, textAlign: "center",
            fontSize: 10, fontWeight: i === todayIdx ? 700 : 500,
            color: i === todayIdx ? "#e0e0e0" : "#333",
          }}>{d.day}</div>
        ))}
      </div>

      {/* Summary Row */}
      <div style={{
        display: "flex", justifyContent: "space-around",
        marginTop: 18, paddingTop: 16,
        borderTop: "1px solid rgba(255,255,255,0.04)",
      }}>
        {[
          { value: totalCompleted + totalAgent, label: "completed", color: "#ddd" },
          { value: "3", label: "in progress", color: "#fbbf24" },
          { value: "7", label: "upcoming", color: "#555" },
        ].map(s => (
          <div key={s.label} style={{ textAlign: "center" }}>
            <div style={{ fontSize: 20, fontWeight: 800, color: s.color, letterSpacing: "-0.02em" }}>{s.value}</div>
            <div style={{ fontSize: 10, fontWeight: 500, color: "#444", marginTop: 2 }}>{s.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function TaskCard({ task, onToggle, index }) {
  const [done, setDone] = useState(false);
  const project = PROJECTS.find(p => p.id === task.project);

  return (
    <div style={{
      display: "flex", gap: 14, alignItems: "flex-start",
      padding: "14px 16px",
      background: done ? "rgba(255,255,255,0.015)" : "rgba(255,255,255,0.035)",
      borderRadius: 12, border: "1px solid rgba(255,255,255,0.06)",
      opacity: done ? 0.35 : 1, transition: "all 0.25s ease",
      animation: `fadeUp 0.35s ease ${index * 0.04}s both`,
      position: "relative", overflow: "hidden",
    }}>


      <button onClick={() => { setDone(!done); if (!done && onToggle) onToggle(); }} style={{
        width: 20, height: 20, minWidth: 20, borderRadius: 6,
        border: done ? "none" : `2px solid ${project?.color || "#555"}40`,
        background: done ? (project?.color || "#555") : "transparent",
        cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
        marginTop: 1, transition: "all 0.15s",
      }}>
        {done && <svg width="11" height="11" viewBox="0 0 16 16" fill="none"><path d="M3 8.5L6.5 12L13 4" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/></svg>}
      </button>

      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 13.5, fontWeight: 600, color: done ? "#444" : "#ddd",
          textDecoration: done ? "line-through" : "none", lineHeight: 1.35, marginBottom: 5,
        }}>{task.title}</div>
        <div style={{ display: "flex", alignItems: "center", gap: 6, flexWrap: "wrap" }}>
          <span style={{
            fontSize: 10, fontWeight: 600, color: project?.color,
            background: `${project?.color}12`, padding: "1px 7px", borderRadius: 5,
            border: `1px solid ${project?.color}18`,
          }}>{project?.emoji} {project?.name}</span>
          {task.time && <span style={{
            fontSize: 10, fontWeight: 500, color: "#555",
            background: "rgba(255,255,255,0.04)", padding: "1px 6px", borderRadius: 4,
          }}>{task.time}</span>}
          {task.subtasks && <span style={{ fontSize: 10, fontWeight: 500, color: "#444" }}>☐ {task.subtasks.done}/{task.subtasks.total}</span>}
        </div>
      </div>

      {task.agent && (
        <div style={{
          display: "flex", alignItems: "center", gap: 4, padding: "3px 8px", borderRadius: 7,
          background: task.agentStatus === "done" ? "rgba(52,211,153,0.08)" : "rgba(251,191,36,0.08)",
          border: `1px solid ${task.agentStatus === "done" ? "rgba(52,211,153,0.12)" : "rgba(251,191,36,0.12)"}`,
        }}>
          <span style={{ fontSize: 10 }}>🤖</span>
          <span style={{ fontSize: 10, fontWeight: 600, color: task.agentStatus === "done" ? "#34d399" : "#fbbf24" }}>
            {task.agentStatus === "done" ? "Review" : "Working"}
          </span>
          {task.agentStatus === "working" && <div style={{ width: 4, height: 4, borderRadius: "50%", background: "#fbbf24", animation: "pulse 1.5s ease infinite" }} />}
        </div>
      )}
    </div>
  );
}

function ProjectCard({ project, count, index }) {
  const [h, setH] = useState(false);
  return (
    <div onMouseEnter={() => setH(true)} onMouseLeave={() => setH(false)} style={{
      display: "flex", alignItems: "center", gap: 12,
      padding: "14px 16px", borderRadius: 12,
      background: h ? "rgba(255,255,255,0.055)" : "rgba(255,255,255,0.035)",
      border: h ? `1px solid ${project.color}25` : "1px solid rgba(255,255,255,0.06)",
      cursor: "pointer", transition: "all 0.15s",
      animation: `fadeUp 0.35s ease ${0.2 + index * 0.04}s both`,
    }}>
      <span style={{ fontSize: 20 }}>{project.emoji}</span>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: "#ccc" }}>{project.name}</div>
        <div style={{ fontSize: 11, fontWeight: 500, color: "#444", marginTop: 1 }}>{count} tasks</div>
      </div>
      <svg width="14" height="14" viewBox="0 0 16 16" fill="none" style={{ opacity: 0.2 }}>
        <path d="M6 4L10 8L6 12" stroke="#888" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    </div>
  );
}

export default function ClawDeckHome() {
  const [greeting, setGreeting] = useState("");
  const [dateStr, setDateStr] = useState("");
  const [completedToday, setCompletedToday] = useState(2);
  const [activeNav, setActiveNav] = useState("home");
  const [currentBoard, setCurrentBoard] = useState(BOARDS[0]);
  const total = TODAY_TASKS.length;

  useEffect(() => {
    const h = new Date().getHours();
    setGreeting(h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening");
    setDateStr(new Date().toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" }));
  }, []);

  const progress = completedToday / total;
  const projectCounts = { clawdeck: 7, tini: 9, gratu: 5, nod: 4, mx: 3 };

  return (
    <div style={{
      minHeight: "100vh", background: "#0c0c0f", color: "#e0e0e0",
      fontFamily: "'Plus Jakarta Sans', system-ui, sans-serif",
    }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
        * { box-sizing: border-box; margin: 0; padding: 0; }
        ::selection { background: #fbbf24; color: #0c0c0f; }
        @keyframes fadeUp { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes dropIn { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes pulse { 0%,100% { opacity: 1; } 50% { opacity: 0.25; } }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.05); border-radius: 10px; }
      `}</style>

      {/* ─── Top Nav ─── */}
      <nav style={{
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "0 24px", height: 52,
        borderBottom: "1px solid rgba(255,255,255,0.06)",
        background: "#0c0c0f", position: "sticky", top: 0, zIndex: 100,
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
          <BoardSwitcher currentBoard={currentBoard} onSwitch={setCurrentBoard} />
          <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
            {["home", "boards"].map(id => (
              <button key={id} onClick={() => setActiveNav(id)} style={{
                fontSize: 13, fontWeight: 600,
                color: activeNav === id ? "#e0e0e0" : "#555",
                background: activeNav === id ? "rgba(255,255,255,0.06)" : "transparent",
                border: "none", cursor: "pointer",
                padding: "6px 14px", borderRadius: 8, transition: "all 0.15s", textTransform: "capitalize",
              }}>{id}</button>
            ))}
          </div>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 16, fontSize: 12, fontWeight: 500, color: "#444" }}>
          <span>0 inbox</span>
          <span style={{ color: "#333" }}>|</span>
          <span>1 in progress</span>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <button style={{
            fontSize: 12, fontWeight: 600, color: "#888",
            background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.06)",
            padding: "5px 12px", borderRadius: 8, cursor: "pointer",
            display: "flex", alignItems: "center", gap: 5,
          }}><span style={{ fontSize: 11, opacity: 0.5 }}>⌘</span>K</button>
          <button style={{
            display: "flex", alignItems: "center", gap: 6,
            fontSize: 12, fontWeight: 600, color: "#888",
            background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.06)",
            padding: "5px 12px", borderRadius: 8, cursor: "pointer",
          }}>
            <svg width="14" height="14" viewBox="0 0 16 16" fill="none"><path d="M14 8H2M8 2V14" stroke="#888" strokeWidth="1.5" strokeLinecap="round"/></svg>
            Add card
          </button>
          <UserProfileDropdown />
        </div>
      </nav>

      {/* ─── Single Column Content ─── */}
      <div style={{ maxWidth: 540, margin: "0 auto", padding: "0 20px" }}>

        {/* Greeting + Progress */}
        <div style={{
          padding: "36px 0 0", display: "flex", alignItems: "flex-end", justifyContent: "space-between",
          animation: "fadeUp 0.35s ease both",
        }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: "#444", letterSpacing: "0.06em", textTransform: "uppercase", marginBottom: 8 }}>{dateStr}</div>
            <h1 style={{ fontSize: 28, fontWeight: 800, color: "#f0f0f0", letterSpacing: "-0.03em", lineHeight: 1.15 }}>{greeting}, Max</h1>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: 22, fontWeight: 800, color: "#f0f0f0", letterSpacing: "-0.02em" }}>{completedToday}/{total}</div>
              <div style={{ fontSize: 11, fontWeight: 500, color: "#444" }}>done today</div>
            </div>
            <div style={{ position: "relative", width: 44, height: 44 }}>
              <svg width="44" height="44" viewBox="0 0 44 44" style={{ transform: "rotate(-90deg)" }}>
                <circle cx="22" cy="22" r="18" fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="4" />
                <circle cx="22" cy="22" r="18" fill="none" stroke="#ef4444" strokeWidth="4"
                  strokeDasharray={`${progress * 113} 113`} strokeLinecap="round"
                  style={{ transition: "stroke-dasharray 0.6s ease" }} />
              </svg>
            </div>
          </div>
        </div>

        {/* Agent status bar */}
        <div style={{
          display: "flex", alignItems: "center", gap: 6, padding: "16px 0 24px",
          animation: "fadeUp 0.35s ease 0.04s both",
        }}>
          <div style={{ width: 5, height: 5, borderRadius: "50%", background: "#fbbf24", animation: "pulse 2s ease infinite" }} />
          <span style={{ fontSize: 11, fontWeight: 600, color: "#fbbf24" }}>Agent working on 2 tasks</span>
        </div>

        {/* Today */}
        <div style={{ marginBottom: 32 }}>
          <div style={{
            display: "flex", alignItems: "center", justifyContent: "space-between",
            marginBottom: 10, animation: "fadeUp 0.35s ease 0.06s both",
          }}>
            <h2 style={{ fontSize: 14, fontWeight: 700, color: "#999" }}>Today</h2>
            <button style={{ fontSize: 11, fontWeight: 600, color: "#444", background: "none", border: "none", cursor: "pointer" }}>View board →</button>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 5 }}>
            {TODAY_TASKS.map((t, i) => (
              <TaskCard key={t.id} task={t} index={i} onToggle={() => setCompletedToday(p => Math.min(p + 1, total))} />
            ))}
          </div>
        </div>

        {/* Agent Activity */}
        <div style={{ marginBottom: 32 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 7, marginBottom: 10, animation: "fadeUp 0.35s ease 0.28s both" }}>
            <span style={{ fontSize: 13 }}>🤖</span>
            <h2 style={{ fontSize: 14, fontWeight: 700, color: "#999" }}>Agent Activity</h2>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 5 }}>
            {AGENT_UPDATES.map((u, i) => (
              <div key={u.id} style={{
                padding: "11px 13px", borderRadius: 10,
                background: "rgba(251,191,36,0.03)", border: "1px solid rgba(251,191,36,0.07)",
                animation: `fadeUp 0.35s ease ${0.32 + i * 0.04}s both`,
              }}>
                <div style={{ fontSize: 12, fontWeight: 500, color: "#999", lineHeight: 1.45 }}>{u.text}</div>
                <div style={{ fontSize: 10, fontWeight: 500, color: "#333", marginTop: 4 }}>{u.time}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Suggestions */}
        <div style={{ marginBottom: 32 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 7, marginBottom: 10, animation: "fadeUp 0.35s ease 0.38s both" }}>
            <span style={{ fontSize: 13 }}>💡</span>
            <h2 style={{ fontSize: 14, fontWeight: 700, color: "#999" }}>Suggestions</h2>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 5 }}>
            {NUDGES.map((n, i) => (
              <div key={n.id} style={{
                padding: "11px 13px", borderRadius: 10,
                background: "rgba(251,191,36,0.04)", border: "1px solid rgba(251,191,36,0.08)",
                display: "flex", alignItems: "center", gap: 10,
                animation: `fadeUp 0.35s ease ${0.42 + i * 0.04}s both`,
              }}>
                <div style={{ flex: 1, fontSize: 12, fontWeight: 500, color: "#999", lineHeight: 1.4 }}>{n.text}</div>
                <button style={{
                  fontSize: 11, fontWeight: 600, color: "#fbbf24",
                  background: "rgba(251,191,36,0.08)", border: "1px solid rgba(251,191,36,0.12)",
                  padding: "4px 10px", borderRadius: 7, cursor: "pointer", whiteSpace: "nowrap",
                }}>{n.action}</button>
              </div>
            ))}
          </div>
        </div>

        {/* This Week — Activity Chart */}
        <WeeklyActivity />

        {/* Projects */}
        <div style={{ marginBottom: 48 }}>
          <h2 style={{ fontSize: 14, fontWeight: 700, color: "#999", marginBottom: 10, animation: "fadeUp 0.35s ease 0.52s both" }}>Projects</h2>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 6 }}>
            {PROJECTS.map((p, i) => (
              <ProjectCard key={p.id} project={p} count={projectCounts[p.id]} index={i} />
            ))}
          </div>
        </div>

      </div>
    </div>
  );
}
