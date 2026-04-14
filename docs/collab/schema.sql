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

CREATE TABLE IF NOT EXISTS external_tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id TEXT NOT NULL UNIQUE,
  created_at_utc TEXT NOT NULL,
  from_external_app TEXT NOT NULL,
  requester TEXT NOT NULL,
  title TEXT NOT NULL,
  objective TEXT NOT NULL,
  priority TEXT NOT NULL,
  urgency TEXT NOT NULL,
  status TEXT NOT NULL,
  owner TEXT NOT NULL,
  inbox_path TEXT NOT NULL,
  latest_message TEXT,
  updated_at_utc TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

CREATE INDEX IF NOT EXISTS idx_external_tasks_status
ON external_tasks (status, updated_at_utc);

CREATE TABLE IF NOT EXISTS external_task_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id TEXT NOT NULL,
  timestamp_utc TEXT NOT NULL,
  event TEXT NOT NULL,
  status TEXT NOT NULL,
  owner TEXT NOT NULL,
  agent_app TEXT NOT NULL,
  session_id TEXT NOT NULL,
  message TEXT NOT NULL,
  outbox_path TEXT NOT NULL,
  created_at_utc TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

CREATE INDEX IF NOT EXISTS idx_external_task_events_task
ON external_task_events (task_id, timestamp_utc);
