PRAGMA journal_mode=WAL;

CREATE TABLE IF NOT EXISTS session_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp_utc TEXT NOT NULL,
  owner TEXT NOT NULL,
  agent_app TEXT NOT NULL,
  session_id TEXT NOT NULL,
  event TEXT NOT NULL,
  status TEXT NOT NULL,
  message TEXT NOT NULL,
  details_json TEXT,
  created_at_utc TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

CREATE INDEX IF NOT EXISTS idx_session_events_session
ON session_events (session_id, timestamp_utc);

CREATE INDEX IF NOT EXISTS idx_session_events_event
ON session_events (event, timestamp_utc);

CREATE TABLE IF NOT EXISTS handoffs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp_utc TEXT NOT NULL,
  owner TEXT NOT NULL,
  agent_app TEXT NOT NULL,
  session_id TEXT NOT NULL,
  handoff_path TEXT NOT NULL,
  summary TEXT,
  created_at_utc TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

CREATE TABLE IF NOT EXISTS lock_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp_utc TEXT NOT NULL,
  owner TEXT NOT NULL,
  session_id TEXT NOT NULL,
  action TEXT NOT NULL,
  lock_file TEXT NOT NULL,
  notes TEXT,
  created_at_utc TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

