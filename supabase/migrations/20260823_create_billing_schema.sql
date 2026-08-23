-- =============================================================================
-- Migration: 20260823_create_billing_schema.sql
-- Purpose:   Creates the transactions and billing_invoices tables for a pure
--            transaction-percentage-based pricing model.
-- =============================================================================

-- 1. Create Transactions Table
CREATE TABLE IF NOT EXISTS public.transactions (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id           UUID        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  customer_id           UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  amount                NUMERIC     NOT NULL CHECK (amount >= 0),
  currency              TEXT        NOT NULL DEFAULT 'MYR',
  platform_fee_percent  NUMERIC     NOT NULL DEFAULT 2.0, -- e.g., 2% fee
  platform_fee_amount   NUMERIC     NOT NULL CHECK (platform_fee_amount >= 0),
  status                TEXT        NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'refunded', 'failed')),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Create Billing Invoices Table
CREATE TABLE IF NOT EXISTS public.billing_invoices (
  id                       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id              UUID        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  billing_month            DATE        NOT NULL, -- Stored as the 1st of the month (e.g., '2026-08-01')
  transaction_count        INTEGER     NOT NULL DEFAULT 0,
  gross_volume             NUMERIC     NOT NULL DEFAULT 0.0,
  transaction_fees_total   NUMERIC     NOT NULL DEFAULT 0.0,
  is_waived                BOOLEAN     NOT NULL DEFAULT FALSE, -- True if within the 1-month grace period
  amount_due               NUMERIC     NOT NULL DEFAULT 0.0, -- This is 0.0 if is_waived is true
  status                   TEXT        NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'unpaid', 'paid', 'waived')),
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Enable RLS
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_invoices ENABLE ROW LEVEL SECURITY;

-- 4. RLS for Transactions
-- Owners can read their own transactions
CREATE POLICY "owners_read_own_transactions" ON public.transactions
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = transactions.business_id AND b.owner_user_id = auth.uid())
  );

-- Customers can read their own transactions
CREATE POLICY "customers_read_own_transactions" ON public.transactions
  FOR SELECT USING (auth.uid() = customer_id);

-- Super Admins can see all transactions
CREATE POLICY "super_admins_all_transactions" ON public.transactions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.user_roles ur WHERE ur.user_id = auth.uid() AND ur.role = 'super_admin')
  );

-- 5. RLS for Billing Invoices
-- Owners can read their own invoices
CREATE POLICY "owners_read_own_invoices" ON public.billing_invoices
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = billing_invoices.business_id AND b.owner_user_id = auth.uid())
  );

-- Super Admins can see all invoices
CREATE POLICY "super_admins_all_invoices" ON public.billing_invoices
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.user_roles ur WHERE ur.user_id = auth.uid() AND ur.role = 'super_admin')
  );

-- 6. Helper Function: Calculate if business is in grace period
-- Returns true if the business was created less than exactly 1 month ago.
-- PostgreSQL automatically handles 28/29/30/31 day months cleanly with '1 month' intervals!
CREATE OR REPLACE FUNCTION public.is_business_in_grace_period(p_business_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_created_at TIMESTAMPTZ;
BEGIN
  SELECT created_at INTO v_created_at FROM public.businesses WHERE id = p_business_id;
  RETURN NOW() < (v_created_at + INTERVAL '1 month');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
