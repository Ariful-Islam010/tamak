-- ============================================================
-- Tobacco Awareness Application — 100% Frontend Matched Schema
-- Database: tamak
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Users Table (Authentication: Email & Google Sign-in)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT,
    google_id TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. User Profiles Table (Onboarding Assessment & User Details)
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    display_name TEXT,
    photo_url TEXT,
    age INTEGER,
    gender TEXT,
    educational_info TEXT,
    plan_duration INTEGER,
    quit_date TIMESTAMPTZ,
    ai_quit_plan TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Daily Check-ins Table (Daily Progress & Optional Reflection Note)
CREATE TABLE daily_checkins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    check_in_date DATE NOT NULL,
    mood TEXT,
    craving_level INTEGER CHECK (craving_level BETWEEN 1 AND 10),
    used_tobacco BOOLEAN DEFAULT FALSE,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, check_in_date)
);

-- 4. Gamification Progress Table (Streak Tracking & Unlocked Badges Array)
CREATE TABLE gamification_progress (
    user_id UUID PRIMARY KEY REFERENCES user_profiles(id) ON DELETE CASCADE,
    longest_streak INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    badges TEXT[] DEFAULT '{}',
    last_check_in_date DATE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Money Saver Goals Table (User's Savings Goals & Dreams)
CREATE TABLE money_saver_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    target_amount NUMERIC(12,2) NOT NULL,
    current_amount NUMERIC(12,2) DEFAULT 0,
    icon_name TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Savings Logs Table (Daily Money Savings History)
CREATE TABLE savings_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Peer Support Messages Table (Community Support Chat)
CREATE TABLE peer_support_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Media Files Table (Uploaded Images & Profile Photos)
CREATE TABLE media_files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    file_name TEXT,
    file_size_bytes BIGINT,
    mime_type TEXT,
    url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. SOS Logs Table (Emergency SOS Usage Log for "Life Saver" Badge)
CREATE TABLE sos_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    trigger_time TIMESTAMPTZ DEFAULT NOW(),
    selected_mode TEXT,
    distraction_clicked TEXT
);

-- 10. Auto Trigger for User Signup (Creates Profile & Gamification Row Automatically)
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_profiles (id) VALUES (NEW.id);
    INSERT INTO gamification_progress (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_user_created
AFTER INSERT ON users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 11. User Reports Table (UGC Moderation & Content Reporting)
CREATE TABLE IF NOT EXISTS user_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    message_id UUID REFERENCES peer_support_messages(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. High Performance B-Tree Indexes
CREATE INDEX IF NOT EXISTS idx_daily_checkins_user_date ON daily_checkins (user_id, check_in_date);
CREATE INDEX IF NOT EXISTS idx_peer_support_messages_created ON peer_support_messages (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_savings_logs_user ON savings_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_money_saver_goals_user ON money_saver_goals (user_id);
CREATE INDEX IF NOT EXISTS idx_sos_logs_user ON sos_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_created ON user_reports (created_at DESC);

