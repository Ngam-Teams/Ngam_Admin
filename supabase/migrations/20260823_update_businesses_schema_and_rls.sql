-- =============================================================================
-- Migration: 20260823_update_businesses_schema_and_rls.sql
-- Purpose:   Updates the public.businesses table to match the new BusinessSummaryModel,
--            applying a 'business_' prefix to columns for clarity, and strictly
--            enforces Row-Level Security (RLS) to prevent data leaks.
-- =============================================================================

-- 0. Drop views that might depend on these columns to allow renaming
DROP VIEW IF EXISTS public.admin_tenant_view;

-- 1. Rename existing columns to have 'business_' prefix and match the Dart model
--    Wrapped in a DO block to make it idempotent (safe to run multiple times).
DO $$ 
BEGIN
  IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='businesses' AND column_name='trading_name') THEN
    ALTER TABLE public.businesses RENAME COLUMN trading_name TO business_name;
  END IF;

  IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='businesses' AND column_name='category') THEN
    ALTER TABLE public.businesses RENAME COLUMN category TO business_industry;
  END IF;

  IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='businesses' AND column_name='ssm_number') THEN
    ALTER TABLE public.businesses RENAME COLUMN ssm_number TO business_registration_number;
  END IF;

  IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='businesses' AND column_name='logo_url') THEN
    ALTER TABLE public.businesses RENAME COLUMN logo_url TO business_logo_url;
  END IF;

  IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='businesses' AND column_name='cover_url') THEN
    ALTER TABLE public.businesses RENAME COLUMN cover_url TO business_cover_url;
  END IF;

  IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='businesses' AND column_name='city') THEN
    ALTER TABLE public.businesses RENAME COLUMN city TO business_city;
  END IF;

  IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='businesses' AND column_name='owner_id') THEN
    ALTER TABLE public.businesses RENAME COLUMN owner_id TO owner_user_id;
  END IF;
END $$;
-- 2. Add missing columns with 'business_' prefix
ALTER TABLE public.businesses 
  ADD COLUMN IF NOT EXISTS business_email TEXT,
  ADD COLUMN IF NOT EXISTS business_subscription_tier TEXT DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS business_phone TEXT,
  ADD COLUMN IF NOT EXISTS business_website TEXT,
  ADD COLUMN IF NOT EXISTS business_country TEXT;

-- 3. Drop existing permissive RLS policies
DROP POLICY IF EXISTS "owners can select own business" ON public.businesses;
DROP POLICY IF EXISTS "owners can update own business" ON public.businesses;
DROP POLICY IF EXISTS "owners can delete own business" ON public.businesses;
DROP POLICY IF EXISTS "owners can insert own business" ON public.businesses;

-- 4. Create bulletproof RLS policies for public.businesses
-- Enable RLS just to be sure
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;

-- 4a. Owners can do everything to their own business
CREATE POLICY "owners_select_own_business"
  ON public.businesses FOR SELECT 
  USING (auth.uid() = owner_user_id);

CREATE POLICY "owners_update_own_business"
  ON public.businesses FOR UPDATE 
  USING (auth.uid() = owner_user_id)
  WITH CHECK (auth.uid() = owner_user_id);

CREATE POLICY "owners_insert_own_business"
  ON public.businesses FOR INSERT 
  WITH CHECK (auth.uid() = owner_user_id);

CREATE POLICY "owners_delete_own_business"
  ON public.businesses FOR DELETE 
  USING (auth.uid() = owner_user_id);

-- 4b. Super Admins can do everything to all businesses
-- We use a subquery to check if the current user has the 'super_admin' role in user_roles.
CREATE POLICY "super_admins_all_access_businesses"
  ON public.businesses FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles 
      WHERE user_roles.user_id = auth.uid() 
      AND user_roles.role = 'super_admin'
    )
  );

-- 5. Update admin_tenant_view for Super Admins
-- Recreate the view to use the new column names and point directly to public.businesses
DROP VIEW IF EXISTS public.admin_tenant_view;
CREATE VIEW public.admin_tenant_view AS
SELECT b.*
FROM public.businesses b
JOIN public.user_roles ur ON ur.user_id = auth.uid()
WHERE ur.role = 'super_admin';

-- 6. Clean up the old admin_business_view as it's no longer used and its dependencies may not exist
DROP VIEW IF EXISTS public.admin_business_view;
