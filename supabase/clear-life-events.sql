-- Clear death/life events history for ALL players
-- This deletes all rows from public.life_events.
-- Run with caution.

BEGIN;

-- Option A (fast): truncate table and reset identity.
-- Requires adequate privileges; may be blocked by RLS in some setups.
TRUNCATE TABLE public.life_events RESTART IDENTITY;

-- If TRUNCATE is not allowed, comment it out and use Option B instead:
-- DELETE FROM public.life_events;

COMMIT;
