-- Add paid_at to bills.
--
-- The app derives a bill's displayed status (paid / scheduled / overdue) from
-- this timestamp, not from the stored `status` string (which is treated as a
-- stale snapshot). Marking a bill paid sets paid_at; the bill reads as paid
-- only while paid_at falls within the current billing cycle, then auto-flips
-- back when the calendar advances. Without persisting paid_at, paid state was
-- lost on every app relaunch.
--
-- Nullable, additive — no backfill, no data loss.

ALTER TABLE public.bills
    ADD COLUMN IF NOT EXISTS paid_at timestamptz;

COMMENT ON COLUMN public.bills.paid_at IS
    'Timestamp of the most recent mark-paid action. The app derives displayed paid status from this (paid only within the current billing cycle), not from the status column.';
