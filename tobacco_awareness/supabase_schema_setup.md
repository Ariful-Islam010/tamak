# Supabase Database Reset & Initialization SQL

Please run the following SQL script in your **Supabase SQL Editor** to drop all existing tables and re-create them with the correct columns, relationships, triggers, row-level security (RLS) policies, and realtime subscription capabilities.

```sql
-- --------------------------------------------------------
-- 1. DROP EXISTING TABLES AND TRIGGERS (RESET DATABASE)
-- --------------------------------------------------------

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

DROP TABLE IF EXISTS public.user_badges CASCADE;
DROP TABLE IF EXISTS public.user_mission_progress CASCADE;
DROP TABLE IF EXISTS public.daily_checkins CASCADE;
DROP TABLE IF EXISTS public.peer_support_messages CASCADE;
DROP TABLE IF EXISTS public.wishlist_items CASCADE;
DROP TABLE IF EXISTS public.savings_logs CASCADE;
DROP TABLE IF EXISTS public.money_saver_goals CASCADE;
DROP TABLE IF EXISTS public.sos_logs CASCADE;
DROP TABLE IF EXISTS public.gamification_progress CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;
DROP TABLE IF EXISTS public.missions CASCADE;
DROP TABLE IF EXISTS public.badges CASCADE;
DROP TABLE IF EXISTS public.education_articles CASCADE;

-- --------------------------------------------------------
-- 2. CREATE TABLES
-- --------------------------------------------------------

-- Enable UUID generation extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: user_profiles
CREATE TABLE public.user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    display_name TEXT,
    photo_url TEXT,
    educational_info TEXT,
    tobacco_type TEXT,
    plan_duration INTEGER,
    quit_date TIMESTAMP WITH TIME ZONE,
    ai_quit_plan TEXT,
    age INTEGER,
    gender TEXT,
    consumption_habits TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: daily_checkins
CREATE TABLE public.daily_checkins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    check_in_date DATE NOT NULL,
    mood TEXT,
    craving_level INTEGER,
    smoked_today BOOLEAN,
    used_tobacco BOOLEAN,
    cigarettes_smoked INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, check_in_date)
);

-- Table: gamification_progress
CREATE TABLE public.gamification_progress (
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE PRIMARY KEY,
    level INTEGER DEFAULT 1,
    current_xp INTEGER DEFAULT 0,
    total_xp INTEGER DEFAULT 0,
    badges TEXT[] DEFAULT '{}',
    longest_streak INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    last_check_in_date DATE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: money_saver_goals
CREATE TABLE public.money_saver_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    target_amount NUMERIC NOT NULL,
    current_amount NUMERIC DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    icon_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: peer_support_messages
CREATE TABLE public.peer_support_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: wishlist_items
CREATE TABLE public.wishlist_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    item_name VARCHAR(150) NOT NULL,
    target_amount INTEGER NOT NULL CHECK (target_amount > 0),
    category_icon VARCHAR(50) NOT NULL,
    is_achieved BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: savings_logs
CREATE TABLE public.savings_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL CHECK (amount > 0),
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: missions
CREATE TABLE public.missions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    reward_xp INTEGER NOT NULL CHECK (reward_xp >= 0),
    mission_type VARCHAR(50) NOT NULL CHECK (mission_type IN ('DAILY', 'STREAK', 'ONBOARDING'))
);

-- Table: user_mission_progress
CREATE TABLE public.user_mission_progress (
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    mission_id UUID NOT NULL REFERENCES public.missions(id) ON DELETE CASCADE,
    progress_date DATE NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (user_id, mission_id, progress_date)
);

-- Table: badges
CREATE TABLE public.badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(100) NOT NULL UNIQUE,
    icon VARCHAR(50) NOT NULL,
    color VARCHAR(10) NOT NULL
);

-- Table: user_badges
CREATE TABLE public.user_badges (
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    badge_id UUID NOT NULL REFERENCES public.badges(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, badge_id)
);

-- Table: education_articles
CREATE TABLE public.education_articles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(20) NOT NULL CHECK (type IN ('ARTICLE', 'MYTH_FACT')),
    title_or_myth VARCHAR(255) NOT NULL,
    content_or_fact TEXT NOT NULL,
    category VARCHAR(100),
    icon VARCHAR(50),
    color VARCHAR(10)
);

-- Table: sos_logs
CREATE TABLE public.sos_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    trigger_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    selected_mode VARCHAR(50) NOT NULL CHECK (selected_mode IN ('WAIT_5_MINS', '4_7_8_BREATHING')),
    distraction_clicked VARCHAR(50) CHECK (distraction_clicked IN ('WATER', 'FRIEND', 'WALK'))
);

-- --------------------------------------------------------
-- 3. ENABLE ROW LEVEL SECURITY (RLS) AND POLICIES
-- --------------------------------------------------------

-- user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view all profiles" ON public.user_profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.user_profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = id);

-- daily_checkins
ALTER TABLE public.daily_checkins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own checkins" ON public.daily_checkins FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own checkins" ON public.daily_checkins FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own checkins" ON public.daily_checkins FOR UPDATE USING (auth.uid() = user_id);

-- gamification_progress
ALTER TABLE public.gamification_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own progress" ON public.gamification_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own progress" ON public.gamification_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own progress" ON public.gamification_progress FOR UPDATE USING (auth.uid() = user_id);

-- money_saver_goals
ALTER TABLE public.money_saver_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own goals" ON public.money_saver_goals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own goals" ON public.money_saver_goals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own goals" ON public.money_saver_goals FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own goals" ON public.money_saver_goals FOR DELETE USING (auth.uid() = user_id);

-- peer_support_messages
ALTER TABLE public.peer_support_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view all messages" ON public.peer_support_messages FOR SELECT USING (true);
CREATE POLICY "Users can insert own messages" ON public.peer_support_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Users can delete own messages" ON public.peer_support_messages FOR DELETE USING (auth.uid() = sender_id);

-- --------------------------------------------------------
-- 4. AUTOMATIC NEW USER INITIALIZATION TRIGGER
-- --------------------------------------------------------

CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, display_name, photo_url)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'display_name', 'ব্যবহারকারী'),
    new.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  
  INSERT INTO public.gamification_progress (user_id)
  VALUES (new.id)
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- --------------------------------------------------------
-- 5. ENABLE REALTIME SUBSCRIPTIONS
-- --------------------------------------------------------

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'peer_support_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.peer_support_messages;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Could not add peer_support_messages to realtime publication: %', SQLERRM;
END $$;
```
