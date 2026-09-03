/// Skema SQLite untuk storan tempatan (SPEC 2.6). Disimpan sebagai teks di sini
/// supaya `family_graph` kekal pure Dart tanpa kebergantungan Drift; app Flutter
/// (Fasa 3) menjana lapisan Drift daripada skema yang SAMA.
///
/// Guna soft delete (`deleted_at`) di mana-mana (SPEC 2.6): memadam seseorang
/// secara kekal boleh merosakkan simulasi lama secara senyap.
const String familyGraphSchemaSql = r'''
CREATE TABLE persons (
  id TEXT PRIMARY KEY,
  family_id TEXT NOT NULL,
  name TEXT NOT NULL,
  full_name TEXT,
  gender TEXT NOT NULL CHECK (gender IN ('male','female')),
  birth_date INTEGER,
  status TEXT NOT NULL DEFAULT 'alive' CHECK (status IN ('alive','deceased','unknown')),
  death_date INTEGER,
  photo_path TEXT,
  notes TEXT,
  is_self INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE TABLE parent_links (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES persons(id),
  parent_id TEXT NOT NULL REFERENCES persons(id),
  role TEXT NOT NULL CHECK (role IN ('father','mother')),
  nasab_status TEXT NOT NULL DEFAULT 'confirmed',
  kind TEXT NOT NULL DEFAULT 'biological' CHECK (kind IN ('biological','adoptive','step')),
  is_private INTEGER NOT NULL DEFAULT 1,
  UNIQUE(child_id, role, parent_id)
);

CREATE TABLE spouse_links (
  id TEXT PRIMARY KEY,
  person_a_id TEXT NOT NULL REFERENCES persons(id),
  person_b_id TEXT NOT NULL REFERENCES persons(id),
  status TEXT NOT NULL CHECK (status IN ('married','divorced','widowed')),
  marriage_date INTEGER,
  end_date INTEGER,
  marriage_order INTEGER
);

CREATE TABLE simulations (
  id TEXT PRIMARY KEY,
  family_id TEXT NOT NULL,
  deceased_id TEXT NOT NULL,
  simulation_date INTEGER NOT NULL,
  snapshot_json TEXT NOT NULL,
  result_json TEXT NOT NULL,
  ruleset_version TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE INDEX idx_parent_links_child ON parent_links(child_id);
CREATE INDEX idx_parent_links_parent ON parent_links(parent_id);
CREATE INDEX idx_spouse_links_a ON spouse_links(person_a_id);
CREATE INDEX idx_spouse_links_b ON spouse_links(person_b_id);
CREATE INDEX idx_persons_family ON persons(family_id);
CREATE INDEX idx_simulations_family ON simulations(family_id);
''';
