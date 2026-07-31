-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.user_profiles (
  id uuid NOT NULL,
  email text,
  display_name text,
  photo_url text,
  educational_info text,
  plan_duration integer,
  quit_date timestamp with time zone,
  ai_quit_plan text,
  age integer,
  gender text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  sos_friends jsonb DEFAULT '[]'::jsonb,
  CONSTRAINT user_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT user_profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.daily_checkins (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  check_in_date date NOT NULL,
  mood text,
  craving_level integer,
  used_tobacco boolean,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT daily_checkins_pkey PRIMARY KEY (id),
  CONSTRAINT daily_checkins_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.gamification_progress (
  user_id uuid NOT NULL,
  badges ARRAY DEFAULT '{}'::text[],
  longest_streak integer DEFAULT 0,
  current_streak integer DEFAULT 0,
  last_check_in_date date,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT gamification_progress_pkey PRIMARY KEY (user_id),
  CONSTRAINT gamification_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.money_saver_goals (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  title text NOT NULL,
  target_amount numeric NOT NULL,
  current_amount numeric DEFAULT 0,
  is_completed boolean DEFAULT false,
  icon_name text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT money_saver_goals_pkey PRIMARY KEY (id),
  CONSTRAINT money_saver_goals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.peer_support_messages (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  sender_id uuid,
  content text NOT NULL,
  image_url text,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT peer_support_messages_pkey PRIMARY KEY (id),
  CONSTRAINT peer_support_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.savings_logs (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  amount integer NOT NULL CHECK (amount > 0),
  logged_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT savings_logs_pkey PRIMARY KEY (id),
  CONSTRAINT savings_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.sos_logs (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  trigger_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  selected_mode character varying NOT NULL CHECK (selected_mode::text = ANY (ARRAY['WAIT_5_MINS'::character varying, '4_7_8_BREATHING'::character varying]::text[])),
  distraction_clicked character varying CHECK (distraction_clicked::text = ANY (ARRAY['WATER'::character varying, 'FRIEND'::character varying, 'WALK'::character varying]::text[])),
  CONSTRAINT sos_logs_pkey PRIMARY KEY (id),
  CONSTRAINT sos_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);