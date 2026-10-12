-- 人生編年史 Life Chronicle：空白 SQLite schema v1
-- 由實際 APP schema 產生；含 CHECK、索引、FTS5 與層級觸發器。
-- 只能用於新建空白資料庫，不是既有資料庫的遷移腳本。
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

CREATE TABLE "archive_sessions" ("archive_session_id" TEXT NOT NULL, "subject_id" TEXT NOT NULL REFERENCES subjects (subject_id), "activated_at" TEXT NOT NULL, "activated_by" TEXT NOT NULL REFERENCES authors (author_id), "deactivated_at" TEXT NULL, "deactivated_by" TEXT NULL REFERENCES authors (author_id), PRIMARY KEY ("archive_session_id"));

CREATE TABLE "archive_settings" ("subject_id" TEXT NOT NULL REFERENCES subjects (subject_id), "mode" TEXT NOT NULL DEFAULT 'normal', "current_session_id" TEXT NULL REFERENCES archive_sessions (archive_session_id), PRIMARY KEY ("subject_id"), CHECK (mode IN ('normal', 'life_archive')));

CREATE TABLE "attachments" ("layer" TEXT NOT NULL, "author_id" TEXT NOT NULL REFERENCES authors (author_id), "created_at" TEXT NOT NULL, "archive_session_id" TEXT NULL REFERENCES archive_sessions (archive_session_id), "attachment_id" TEXT NOT NULL, "event_id" TEXT NOT NULL REFERENCES events (event_id), "blob_id" TEXT NOT NULL REFERENCES blobs (blob_id), "display_name" TEXT NOT NULL, "original_filename" TEXT NOT NULL, "role" TEXT NULL, "captured_at" TEXT NULL, "captured_latitude" REAL NULL, "captured_longitude" REAL NULL, "imported_at" TEXT NOT NULL, "storage_mode" TEXT NOT NULL, PRIMARY KEY ("attachment_id"), CHECK ((layer = 'original' AND archive_session_id IS NULL) OR (layer = 'remembrance' AND archive_session_id IS NOT NULL)), CHECK ((captured_latitude IS NULL) = (captured_longitude IS NULL)), CHECK (captured_latitude IS NULL OR captured_latitude BETWEEN -90 AND 90), CHECK (captured_longitude IS NULL OR captured_longitude BETWEEN -180 AND 180));

CREATE TABLE "authors" ("author_id" TEXT NOT NULL, "display_name" TEXT NOT NULL, "role" TEXT NOT NULL, "is_subject_self" INTEGER NOT NULL DEFAULT 0 CHECK ("is_subject_self" IN (0, 1)), PRIMARY KEY ("author_id"));

CREATE TABLE "blobs" ("blob_id" TEXT NOT NULL, "sha256" TEXT NOT NULL UNIQUE, "byte_size" INTEGER NOT NULL, "media_type" TEXT NOT NULL, "path" TEXT NOT NULL, "verify_status" TEXT NOT NULL, PRIMARY KEY ("blob_id"));

CREATE TABLE "change_history" ("change_history_id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "entity_id" TEXT NOT NULL, "operation" TEXT NOT NULL, "author_id" TEXT NOT NULL REFERENCES authors (author_id), "timestamp" TEXT NOT NULL);

CREATE TABLE "event_life_periods" ("layer" TEXT NOT NULL, "author_id" TEXT NOT NULL REFERENCES authors (author_id), "created_at" TEXT NOT NULL, "archive_session_id" TEXT NULL REFERENCES archive_sessions (archive_session_id), "event_id" TEXT NOT NULL REFERENCES events (event_id), "life_period_id" TEXT NOT NULL REFERENCES life_periods (life_period_id), PRIMARY KEY ("event_id", "life_period_id"), CHECK ((layer = 'original' AND archive_session_id IS NULL) OR (layer = 'remembrance' AND archive_session_id IS NOT NULL)));

CREATE TABLE "event_links" ("layer" TEXT NOT NULL, "author_id" TEXT NOT NULL REFERENCES authors (author_id), "created_at" TEXT NOT NULL, "archive_session_id" TEXT NULL REFERENCES archive_sessions (archive_session_id), "event_a_id" TEXT NOT NULL REFERENCES events (event_id), "event_b_id" TEXT NOT NULL REFERENCES events (event_id), PRIMARY KEY ("event_a_id", "event_b_id"), CHECK ((layer = 'original' AND archive_session_id IS NULL) OR (layer = 'remembrance' AND archive_session_id IS NOT NULL)), CHECK (event_a_id < event_b_id));

CREATE TABLE "event_people" ("layer" TEXT NOT NULL, "author_id" TEXT NOT NULL REFERENCES authors (author_id), "created_at" TEXT NOT NULL, "archive_session_id" TEXT NULL REFERENCES archive_sessions (archive_session_id), "event_id" TEXT NOT NULL REFERENCES events (event_id), "person_id" TEXT NOT NULL REFERENCES people (person_id), PRIMARY KEY ("event_id", "person_id"), CHECK ((layer = 'original' AND archive_session_id IS NULL) OR (layer = 'remembrance' AND archive_session_id IS NOT NULL)));

CREATE TABLE "event_sections" ("layer" TEXT NOT NULL, "author_id" TEXT NOT NULL REFERENCES authors (author_id), "created_at" TEXT NOT NULL, "archive_session_id" TEXT NULL REFERENCES archive_sessions (archive_session_id), "event_section_id" TEXT NOT NULL, "event_id" TEXT NOT NULL REFERENCES events (event_id), "title" TEXT NULL, "suggestion_key" TEXT NULL, "position" INTEGER NOT NULL, "content_md" TEXT NOT NULL, PRIMARY KEY ("event_section_id"), CHECK ((layer = 'original' AND archive_session_id IS NULL) OR (layer = 'remembrance' AND archive_session_id IS NOT NULL)));

CREATE TABLE "event_tags" ("layer" TEXT NOT NULL, "author_id" TEXT NOT NULL REFERENCES authors (author_id), "created_at" TEXT NOT NULL, "archive_session_id" TEXT NULL REFERENCES archive_sessions (archive_session_id), "event_id" TEXT NOT NULL REFERENCES events (event_id), "tag_id" TEXT NOT NULL REFERENCES tags (tag_id), PRIMARY KEY ("event_id", "tag_id"), CHECK ((layer = 'original' AND archive_session_id IS NULL) OR (layer = 'remembrance' AND archive_session_id IS NOT NULL)));

CREATE TABLE "events" ("layer" TEXT NOT NULL, "author_id" TEXT NOT NULL REFERENCES authors (author_id), "created_at" TEXT NOT NULL, "archive_session_id" TEXT NULL REFERENCES archive_sessions (archive_session_id), "event_id" TEXT NOT NULL, "subject_id" TEXT NOT NULL REFERENCES subjects (subject_id), "title" TEXT NOT NULL, "category" TEXT NULL, "time_payload" TEXT NOT NULL, "sort_start" TEXT NULL, "sort_end" TEXT NULL, "manual_order" INTEGER NOT NULL DEFAULT 0, "place_id" TEXT NULL REFERENCES places (place_id), "privacy" TEXT NOT NULL DEFAULT 'normal', "deleted_at" TEXT NULL, "purged_at" TEXT NULL, "updated_at" TEXT NOT NULL, PRIMARY KEY ("event_id"), CHECK ((layer = 'original' AND archive_session_id IS NULL) OR (layer = 'remembrance' AND archive_session_id IS NOT NULL)), CHECK (privacy IN ('normal', 'private')), CHECK (purged_at IS NULL OR deleted_at IS NOT NULL));

CREATE TABLE "life_periods" ("layer" TEXT NOT NULL, "author_id" TEXT NOT NULL REFERENCES authors (author_id), "created_at" TEXT NOT NULL, "archive_session_id" TEXT NULL REFERENCES archive_sessions (archive_session_id), "life_period_id" TEXT NOT NULL, "subject_id" TEXT NOT NULL REFERENCES subjects (subject_id), "type" TEXT NOT NULL, "start_time" TEXT NOT NULL, "end_time" TEXT NULL, "organization" TEXT NULL, "role" TEXT NULL, PRIMARY KEY ("life_period_id"), CHECK ((layer = 'original' AND archive_session_id IS NULL) OR (layer = 'remembrance' AND archive_session_id IS NOT NULL)));

CREATE TABLE "people" ("person_id" TEXT NOT NULL, "display_name" TEXT NOT NULL, "name_key" TEXT NOT NULL UNIQUE, "created_at" TEXT NOT NULL, PRIMARY KEY ("person_id"));

CREATE TABLE "places" ("place_id" TEXT NOT NULL, "name" TEXT NULL, "name_key" TEXT NULL UNIQUE, "latitude" REAL NULL, "longitude" REAL NULL, "radius_m" REAL NULL, "created_at" TEXT NOT NULL, PRIMARY KEY ("place_id"), CHECK ((name IS NULL) = (name_key IS NULL)), CHECK ((latitude IS NULL) = (longitude IS NULL)), CHECK (name IS NOT NULL OR latitude IS NOT NULL), CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90), CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180), CHECK (radius_m IS NULL OR (radius_m > 0 AND latitude IS NOT NULL)));

CREATE TABLE "reflections" ("layer" TEXT NOT NULL, "author_id" TEXT NOT NULL REFERENCES authors (author_id), "created_at" TEXT NOT NULL, "archive_session_id" TEXT NULL REFERENCES archive_sessions (archive_session_id), "reflection_id" TEXT NOT NULL, "event_id" TEXT NOT NULL REFERENCES events (event_id), "recorded_at" TEXT NOT NULL, "content_md" TEXT NOT NULL, "provenance" TEXT NULL, PRIMARY KEY ("reflection_id"), CHECK ((layer = 'original' AND archive_session_id IS NULL) OR (layer = 'remembrance' AND archive_session_id IS NOT NULL)));

CREATE VIRTUAL TABLE search_index USING fts5(entity_type UNINDEXED, entity_id UNINDEXED, content, tokenize = 'unicode61');

CREATE TABLE "stories" ("layer" TEXT NOT NULL, "author_id" TEXT NOT NULL REFERENCES authors (author_id), "created_at" TEXT NOT NULL, "archive_session_id" TEXT NULL REFERENCES archive_sessions (archive_session_id), "story_id" TEXT NOT NULL, "title" TEXT NOT NULL, PRIMARY KEY ("story_id"), CHECK ((layer = 'original' AND archive_session_id IS NULL) OR (layer = 'remembrance' AND archive_session_id IS NOT NULL)));

CREATE TABLE "story_events" ("story_id" TEXT NOT NULL REFERENCES stories (story_id), "event_id" TEXT NOT NULL REFERENCES events (event_id), "position" INTEGER NOT NULL, PRIMARY KEY ("story_id", "event_id"));

CREATE TABLE "subjects" ("subject_id" TEXT NOT NULL, "display_name" TEXT NOT NULL, "birth_date" TEXT NULL, "death_date" TEXT NULL, PRIMARY KEY ("subject_id"));

CREATE TABLE "tags" ("tag_id" TEXT NOT NULL, "label" TEXT NOT NULL UNIQUE, PRIMARY KEY ("tag_id"));

CREATE INDEX events_sort_end ON events (sort_end);

CREATE INDEX events_sort_start ON events (sort_start);

CREATE TRIGGER attachments_layer_immutable BEFORE UPDATE OF layer ON attachments BEGIN SELECT RAISE(ABORT, '層級建立後不可變更'); END;

CREATE TRIGGER attachments_remembrance_author_insert BEFORE INSERT ON attachments WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER attachments_remembrance_author_update BEFORE UPDATE OF author_id ON attachments WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER authors_self_flag_guard BEFORE UPDATE OF is_subject_self ON authors WHEN NEW.is_subject_self = 1 AND (EXISTS (SELECT 1 FROM events WHERE author_id = NEW.author_id AND layer = 'remembrance') OR EXISTS (SELECT 1 FROM event_sections WHERE author_id = NEW.author_id AND layer = 'remembrance') OR EXISTS (SELECT 1 FROM life_periods WHERE author_id = NEW.author_id AND layer = 'remembrance') OR EXISTS (SELECT 1 FROM reflections WHERE author_id = NEW.author_id AND layer = 'remembrance') OR EXISTS (SELECT 1 FROM stories WHERE author_id = NEW.author_id AND layer = 'remembrance') OR EXISTS (SELECT 1 FROM attachments WHERE author_id = NEW.author_id AND layer = 'remembrance') OR EXISTS (SELECT 1 FROM event_tags WHERE author_id = NEW.author_id AND layer = 'remembrance') OR EXISTS (SELECT 1 FROM event_people WHERE author_id = NEW.author_id AND layer = 'remembrance') OR EXISTS (SELECT 1 FROM event_links WHERE author_id = NEW.author_id AND layer = 'remembrance') OR EXISTS (SELECT 1 FROM event_life_periods WHERE author_id = NEW.author_id AND layer = 'remembrance')) BEGIN SELECT RAISE(ABORT, '此作者已撰寫後續追憶，不可標記為主角本人'); END;

CREATE TRIGGER event_life_periods_layer_immutable BEFORE UPDATE OF layer ON event_life_periods BEGIN SELECT RAISE(ABORT, '層級建立後不可變更'); END;

CREATE TRIGGER event_life_periods_remembrance_author_insert BEFORE INSERT ON event_life_periods WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER event_life_periods_remembrance_author_update BEFORE UPDATE OF author_id ON event_life_periods WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER event_links_layer_immutable BEFORE UPDATE OF layer ON event_links BEGIN SELECT RAISE(ABORT, '層級建立後不可變更'); END;

CREATE TRIGGER event_links_remembrance_author_insert BEFORE INSERT ON event_links WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER event_links_remembrance_author_update BEFORE UPDATE OF author_id ON event_links WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER event_people_layer_immutable BEFORE UPDATE OF layer ON event_people BEGIN SELECT RAISE(ABORT, '層級建立後不可變更'); END;

CREATE TRIGGER event_people_remembrance_author_insert BEFORE INSERT ON event_people WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER event_people_remembrance_author_update BEFORE UPDATE OF author_id ON event_people WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER event_sections_layer_immutable BEFORE UPDATE OF layer ON event_sections BEGIN SELECT RAISE(ABORT, '層級建立後不可變更'); END;

CREATE TRIGGER event_sections_remembrance_author_insert BEFORE INSERT ON event_sections WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER event_sections_remembrance_author_update BEFORE UPDATE OF author_id ON event_sections WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER event_tags_layer_immutable BEFORE UPDATE OF layer ON event_tags BEGIN SELECT RAISE(ABORT, '層級建立後不可變更'); END;

CREATE TRIGGER event_tags_remembrance_author_insert BEFORE INSERT ON event_tags WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER event_tags_remembrance_author_update BEFORE UPDATE OF author_id ON event_tags WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER events_layer_immutable BEFORE UPDATE OF layer ON events BEGIN SELECT RAISE(ABORT, '層級建立後不可變更'); END;

CREATE TRIGGER events_remembrance_author_insert BEFORE INSERT ON events WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER events_remembrance_author_update BEFORE UPDATE OF author_id ON events WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER life_periods_layer_immutable BEFORE UPDATE OF layer ON life_periods BEGIN SELECT RAISE(ABORT, '層級建立後不可變更'); END;

CREATE TRIGGER life_periods_remembrance_author_insert BEFORE INSERT ON life_periods WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER life_periods_remembrance_author_update BEFORE UPDATE OF author_id ON life_periods WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER reflections_layer_immutable BEFORE UPDATE OF layer ON reflections BEGIN SELECT RAISE(ABORT, '層級建立後不可變更'); END;

CREATE TRIGGER reflections_remembrance_author_insert BEFORE INSERT ON reflections WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER reflections_remembrance_author_update BEFORE UPDATE OF author_id ON reflections WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER stories_layer_immutable BEFORE UPDATE OF layer ON stories BEGIN SELECT RAISE(ABORT, '層級建立後不可變更'); END;

CREATE TRIGGER stories_remembrance_author_insert BEFORE INSERT ON stories WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

CREATE TRIGGER stories_remembrance_author_update BEFORE UPDATE OF author_id ON stories WHEN NEW.layer = 'remembrance' AND EXISTS (SELECT 1 FROM authors WHERE author_id = NEW.author_id AND is_subject_self = 1) BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END;

PRAGMA user_version = 1;
COMMIT;
