-- Migration to drop cigarette-specific columns from daily_checkins
ALTER TABLE public.daily_checkins DROP COLUMN IF EXISTS cigarettes_smoked;
ALTER TABLE public.daily_checkins DROP COLUMN IF EXISTS smoked_today;
