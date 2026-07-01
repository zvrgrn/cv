'use strict';

/* ---------------- Storage & session model ---------------- */

const STORAGE_KEY = 'vipassana.sessions';
const DURATION_OPTIONS = [5, 10, 15, 20, 30, 45, 60, 90];
const TYPE_INFO = {
  sitting: { label: 'Sitting', icon: '🧘' },
  walking: { label: 'Walking', icon: '🚶' },
};

function loadSessions() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    const parsed = raw ? JSON.parse(raw) : [];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function persistSessions() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(sessions));
}

let sessions = loadSessions().sort((a, b) => new Date(b.start) - new Date(a.start));

function addSession(type, startISO, endISO, plannedMinutes) {
  const session = {
    id: (crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.random()}`),
    type,
    start: startISO,
    end: endISO,
    plannedMinutes,
  };
  sessions.unshift(session);
  sessions.sort((a, b) => new Date(b.start) - new Date(a.start));
  persistSessions();
}

function removeSession(id) {
  sessions = sessions.filter((s) => s.id !== id);
  persistSessions();
}

function sessionMinutes(session) {
  return Math.max(0, Math.round((new Date(session.end) - new Date(session.start)) / 60000));
}

function isSameDay(a, b) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

function startOfDay(date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

function hasSessionOn(date) {
  return sessions.some((s) => isSameDay(new Date(s.start), date));
}

function sessionsOn(date) {
  return sessions.filter((s) => isSameDay(new Date(s.start), date));
}

function currentStreak() {
  let day = startOfDay(new Date());
  if (!hasSessionOn(day)) {
    const yesterday = new Date(day);
    yesterday.setDate(yesterday.getDate() - 1);
    if (!hasSessionOn(yesterday)) return 0;
    day = yesterday;
  }
  let streak = 0;
  while (hasSessionOn(day)) {
    streak += 1;
    day = new Date(day);
    day.setDate(day.getDate() - 1);
  }
  return streak;
}

function longestStreak() {
  const uniqueDays = [...new Set(sessions.map((s) => startOfDay(new Date(s.start)).getTime()))].sort((a, b) => a - b);
  if (uniqueDays.length === 0) return 0;
  let longest = 1;
  let current = 1;
  for (let i = 1; i < uniqueDays.length; i += 1) {
    const diffDays = Math.round((uniqueDays[i] - uniqueDays[i - 1]) / 86400000);
    current = diffDays === 1 ? current + 1 : 1;
    longest = Math.max(longest, current);
  }
  return longest;
}

/* ---------------- Bell (synthesized, no audio file) ---------------- */

const Bell = {
  ctx: null,
  ensureContext() {
    if (!this.ctx) {
      const AudioContextClass = window.AudioContext || window.webkitAudioContext;
      this.ctx = new AudioContextClass();
    }
    if (this.ctx.state === 'suspended') this.ctx.resume();
    return this.ctx;
  },
  ring() {
    let ctx;
    try {
      ctx = this.ensureContext();
    } catch {
      return;
    }
    const duration = 3;
    const now = ctx.currentTime;
    const master = ctx.createGain();
    master.gain.setValueAtTime(0.001, now);
    master.gain.exponentialRampToValueAtTime(0.5, now + 0.02);
    master.gain.exponentialRampToValueAtTime(0.001, now + duration);
    master.connect(ctx.destination);

    [220, 330, 440].forEach((freq) => {
      const osc = ctx.createOscillator();
      osc.type = 'sine';
      osc.frequency.value = freq;
      osc.connect(master);
      osc.start(now);
      osc.stop(now + duration);
    });
  },
};

/* ---------------- Timer engine ---------------- */

const Timer = {
  phase: 'idle', // idle | running | paused | finished
  type: 'sitting',
  minutes: 20,
  remaining: 20 * 60,
  startDate: null,
  intervalId: null,

  configure(type, minutes) {
    this.type = type;
    this.minutes = minutes;
    this.remaining = minutes * 60;
    this.phase = 'idle';
    this.startDate = null;
    clearInterval(this.intervalId);
    renderTimerTab();
  },

  start() {
    if (this.phase !== 'idle' && this.phase !== 'paused') return;
    if (this.phase === 'idle') {
      this.startDate = new Date();
      Bell.ring();
    }
    this.phase = 'running';
    clearInterval(this.intervalId);
    this.intervalId = setInterval(() => this.tick(), 1000);
    renderTimerTab();
  },

  pause() {
    if (this.phase !== 'running') return;
    this.phase = 'paused';
    clearInterval(this.intervalId);
    renderTimerTab();
  },

  reset() {
    clearInterval(this.intervalId);
    this.phase = 'idle';
    this.startDate = null;
    this.remaining = this.minutes * 60;
    renderTimerTab();
  },

  tick() {
    if (this.remaining <= 0) {
      this.finish();
      return;
    }
    this.remaining -= 1;
    if (this.remaining === 0) {
      this.finish();
    } else {
      renderTimerTab();
    }
  },

  finish() {
    clearInterval(this.intervalId);
    this.phase = 'finished';
    Bell.ring();
    if (this.startDate) {
      addSession(this.type, this.startDate.toISOString(), new Date().toISOString(), this.minutes);
      renderProgressTab();
      renderHistoryTab();
    }
    this.startDate = null;
    renderTimerTab();
  },
};

/* ---------------- Tab navigation ---------------- */

function switchTab(tabId) {
  document.querySelectorAll('.tab-panel').forEach((el) => el.classList.toggle('active', el.id === tabId));
  document.querySelectorAll('.tab-btn').forEach((el) => el.classList.toggle('active', el.dataset.tab === tabId));
}

/* ---------------- Timer tab rendering ---------------- */

const DIAL_CIRCUMFERENCE = 2 * Math.PI * 100;

function renderTimerTab() {
  document.querySelectorAll('#type-segmented .segmented-btn').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.type === Timer.type);
    btn.disabled = Timer.phase !== 'idle';
  });

  const durationRow = document.getElementById('duration-row');
  durationRow.style.display = Timer.phase === 'idle' ? 'flex' : 'none';

  const mm = String(Math.floor(Timer.remaining / 60)).padStart(2, '0');
  const ss = String(Timer.remaining % 60).padStart(2, '0');
  document.getElementById('dial-time').textContent = `${mm}:${ss}`;

  const total = Timer.minutes * 60;
  const progress = total > 0 ? 1 - Timer.remaining / total : 0;
  const offset = DIAL_CIRCUMFERENCE * (1 - progress);
  document.getElementById('dial-progress').style.strokeDashoffset = String(offset);

  renderControls();
}

function renderControls() {
  const controls = document.getElementById('controls');
  controls.innerHTML = '';

  if (Timer.phase === 'idle') {
    const btn = document.createElement('button');
    btn.className = 'btn-primary';
    btn.textContent = '▶ Start';
    btn.addEventListener('click', () => Timer.start());
    controls.appendChild(btn);
  } else if (Timer.phase === 'running') {
    controls.appendChild(makeControlButton('⏸ Pause', 'btn-secondary', () => Timer.pause()));
    controls.appendChild(makeControlButton('⏹ Stop', 'btn-danger', () => Timer.reset()));
  } else if (Timer.phase === 'paused') {
    controls.appendChild(makeControlButton('▶ Resume', 'btn-primary', () => Timer.start()));
    controls.appendChild(makeControlButton('⏹ Stop', 'btn-danger', () => Timer.reset()));
  } else if (Timer.phase === 'finished') {
    const box = document.createElement('div');
    box.className = 'finished-box';
    box.innerHTML = '<p>✅ Session complete</p>';
    const btn = document.createElement('button');
    btn.className = 'btn-primary';
    btn.textContent = 'New session';
    btn.addEventListener('click', () => Timer.configure(Timer.type, Timer.minutes));
    box.appendChild(btn);
    controls.appendChild(box);
  }
}

function makeControlButton(label, cls, handler) {
  const btn = document.createElement('button');
  btn.className = cls;
  btn.textContent = label;
  btn.addEventListener('click', handler);
  return btn;
}

function initTimerTab() {
  document.querySelectorAll('#type-segmented .segmented-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      if (Timer.phase !== 'idle') return;
      Timer.configure(btn.dataset.type, Timer.minutes);
    });
  });

  const durationRow = document.getElementById('duration-row');
  DURATION_OPTIONS.forEach((minutes) => {
    const btn = document.createElement('button');
    btn.className = 'duration-btn' + (minutes === Timer.minutes ? ' active' : '');
    btn.textContent = `${minutes} min`;
    btn.dataset.minutes = String(minutes);
    btn.addEventListener('click', () => {
      if (Timer.phase !== 'idle') return;
      Timer.configure(Timer.type, minutes);
      durationRow.querySelectorAll('.duration-btn').forEach((b) => b.classList.toggle('active', b === btn));
    });
    durationRow.appendChild(btn);
  });

  Timer.configure(Timer.type, Timer.minutes);
}

/* ---------------- Progress tab (streaks + calendar) ---------------- */

let displayedMonth = startOfDay(new Date());
displayedMonth.setDate(1);
let selectedDate = startOfDay(new Date());

function renderProgressTab() {
  document.getElementById('stat-current').textContent = String(currentStreak());
  document.getElementById('stat-longest').textContent = String(longestStreak());
  document.getElementById('stat-total').textContent = String(sessions.length);
  renderCalendar();
  renderDaySessions();
}

function daysInGrid(monthDate) {
  const year = monthDate.getFullYear();
  const month = monthDate.getMonth();
  const firstOfMonth = new Date(year, month, 1);
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const leading = firstOfMonth.getDay();
  const days = new Array(leading).fill(null);
  for (let d = 1; d <= daysInMonth; d += 1) {
    days.push(new Date(year, month, d));
  }
  return days;
}

function renderCalendar() {
  document.getElementById('calendar-month-label').textContent =
    displayedMonth.toLocaleDateString(undefined, { month: 'long', year: 'numeric' });

  const grid = document.getElementById('calendar-grid');
  grid.innerHTML = '';

  ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].forEach((w) => {
    const el = document.createElement('div');
    el.className = 'calendar-weekday';
    el.textContent = w;
    grid.appendChild(el);
  });

  const today = new Date();
  daysInGrid(displayedMonth).forEach((date) => {
    const cell = document.createElement('div');
    if (!date) {
      cell.className = 'calendar-cell empty';
      grid.appendChild(cell);
      return;
    }
    cell.className = 'calendar-cell';
    if (isSameDay(date, selectedDate)) cell.classList.add('selected');
    if (isSameDay(date, today)) cell.classList.add('today');

    const num = document.createElement('div');
    num.textContent = String(date.getDate());
    cell.appendChild(num);

    if (hasSessionOn(date)) {
      const dot = document.createElement('div');
      dot.className = 'calendar-dot';
      cell.appendChild(dot);
    }

    cell.addEventListener('click', () => {
      selectedDate = date;
      renderCalendar();
      renderDaySessions();
    });
    grid.appendChild(cell);
  });
}

function renderDaySessions() {
  const container = document.getElementById('day-sessions');
  const daySessions = sessionsOn(selectedDate);
  const dateLabel = selectedDate.toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' });

  if (daySessions.length === 0) {
    container.textContent = `No sessions on ${dateLabel}`;
    return;
  }

  container.innerHTML = '';
  daySessions.forEach((s) => {
    const row = document.createElement('div');
    row.className = 'session-row';
    row.innerHTML = `<span>${TYPE_INFO[s.type].icon} ${TYPE_INFO[s.type].label}</span><span>${sessionMinutes(s)} min</span>`;
    container.appendChild(row);
  });
}

function initProgressTab() {
  document.getElementById('cal-prev').addEventListener('click', () => {
    displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() - 1, 1);
    renderCalendar();
  });
  document.getElementById('cal-next').addEventListener('click', () => {
    displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + 1, 1);
    renderCalendar();
  });
  renderProgressTab();
}

/* ---------------- History tab ---------------- */

function renderHistoryTab() {
  const list = document.getElementById('history-list');
  const emptyHint = document.getElementById('history-empty');
  list.innerHTML = '';

  emptyHint.style.display = sessions.length === 0 ? 'block' : 'none';

  sessions.forEach((s) => {
    const item = document.createElement('div');
    item.className = 'session-item';

    const dateLabel = new Date(s.start).toLocaleString(undefined, {
      day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
    });

    item.innerHTML = `
      <span class="session-icon">${TYPE_INFO[s.type].icon}</span>
      <span class="session-info">
        <div class="session-type">${TYPE_INFO[s.type].label}</div>
        <div class="session-date">${dateLabel}</div>
      </span>
      <span class="session-duration">${sessionMinutes(s)} min</span>
    `;

    const deleteBtn = document.createElement('button');
    deleteBtn.className = 'session-delete';
    deleteBtn.textContent = '✕';
    deleteBtn.addEventListener('click', () => {
      removeSession(s.id);
      renderHistoryTab();
      renderProgressTab();
    });
    item.appendChild(deleteBtn);

    list.appendChild(item);
  });
}

/* ---------------- Settings tab ---------------- */

function initSettingsTab() {
  document.getElementById('export-btn').addEventListener('click', () => {
    const blob = new Blob([JSON.stringify(sessions, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'vipassana-sessions.json';
    a.click();
    URL.revokeObjectURL(url);
  });

  document.getElementById('import-input').addEventListener('change', (event) => {
    const file = event.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const parsed = JSON.parse(String(reader.result));
        if (!Array.isArray(parsed)) throw new Error('not an array');
        sessions = parsed;
        persistSessions();
        renderProgressTab();
        renderHistoryTab();
      } catch {
        alert('Невалиден JSON фајл.');
      }
    };
    reader.readAsText(file);
    event.target.value = '';
  });

  document.getElementById('clear-btn').addEventListener('click', () => {
    if (!confirm('Дали сигурно сакаш да ги избришеш сите сесии?')) return;
    sessions = [];
    persistSessions();
    renderProgressTab();
    renderHistoryTab();
  });
}

/* ---------------- Boot ---------------- */

function init() {
  document.querySelectorAll('.tab-btn').forEach((btn) => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tab));
  });

  initTimerTab();
  initProgressTab();
  renderHistoryTab();
  initSettingsTab();

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('sw.js').catch(() => {});
  }
}

document.addEventListener('DOMContentLoaded', init);
