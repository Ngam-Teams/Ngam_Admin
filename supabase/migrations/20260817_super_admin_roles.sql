-- =============================================================================
-- Migration: Super Admin Role Management Schema
-- Created:   2026-08-17
-- Purpose:   Establishes the authorization hierarchy for Ngam Console.
--            Provides a global user_roles table and a secure view that exposes
--            the full tenants table only to super_admin accounts.
-- =============================================================================

-- 1. Create global user roles table
CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role       TEXT CHECK (role IN ('tenant_admin', 'staff', 'super_admin')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id)
);

-- 2. Enable Row-Level Security (RLS)
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Users can strictly read their own role
CREATE POLICY "Users read own role"
  ON public.user_roles FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- 4. Create a secure view for Super Admins to see all tenants
--    (aggregates the public.tenants table for the Ngam Console dashboard)
CREATE OR REPLACE VIEW public.admin_tenant_view AS
SELECT t.*
FROM   public.tenants t
JOIN   public.user_roles ur ON ur.user_id = auth.uid()
WHERE  ur.role = 'super_admin';
