-- =============================================================================
-- Migration: 20260822_create_businesses_schema.sql
-- Ngam Business Registration Schema
-- Creates: businesses, business_compliance, business_settings
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Core Table: businesses
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.businesses (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  trading_name     TEXT        NOT NULL,
  category         TEXT        NOT NULL CHECK (category IN ('fnb', 'barber', 'retail', 'services')),
  ssm_number       TEXT        NOT NULL UNIQUE,
  sst_number       TEXT,
  logo_url         TEXT,
  cover_url        TEXT,
  address_line     TEXT        NOT NULL,
  postcode         TEXT        NOT NULL,
  city             TEXT        NOT NULL,
  state            TEXT        NOT NULL,
  latitude         FLOAT8,
  longitude        FLOAT8,
  status           TEXT        NOT NULL DEFAULT 'trial' CHECK (status IN ('trial', 'active', 'suspended')),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owners can select own business"   ON public.businesses FOR SELECT USING (auth.uid() = owner_id);
CREATE POLICY "owners can update own business"   ON public.businesses FOR UPDATE USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "owners can delete own business"   ON public.businesses FOR DELETE USING (auth.uid() = owner_id);
CREATE POLICY "owners can insert own business"   ON public.businesses FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- ---------------------------------------------------------------------------
-- 2. Extension Table: business_compliance
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.business_compliance (
  business_id      UUID  PRIMARY KEY REFERENCES public.businesses(id) ON DELETE CASCADE,
  bank_name        TEXT,
  account_holder   TEXT,
  account_number   TEXT,
  epf_number       TEXT,
  socso_number     TEXT,
  eis_number       TEXT
);

ALTER TABLE public.business_compliance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owners can select own compliance" ON public.business_compliance FOR SELECT USING (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_compliance.business_id AND owner_id = auth.uid()));
CREATE POLICY "owners can update own compliance" ON public.business_compliance FOR UPDATE USING (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_compliance.business_id AND owner_id = auth.uid())) WITH CHECK (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_compliance.business_id AND owner_id = auth.uid()));
CREATE POLICY "owners can insert own compliance" ON public.business_compliance FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_compliance.business_id AND owner_id = auth.uid()));
CREATE POLICY "owners can delete own compliance" ON public.business_compliance FOR DELETE USING (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_compliance.business_id AND owner_id = auth.uid()));

-- ---------------------------------------------------------------------------
-- 3. Extension Table: business_settings
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.business_settings (
  business_id      UUID    PRIMARY KEY REFERENCES public.businesses(id) ON DELETE CASCADE,
  operating_hours  JSONB   NOT NULL DEFAULT '{}'::jsonb,
  is_halal         BOOLEAN NOT NULL DEFAULT FALSE,
  total_chairs     INTEGER,
  slot_duration    INTEGER NOT NULL DEFAULT 30
);

ALTER TABLE public.business_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owners can select own settings" ON public.business_settings FOR SELECT USING (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_settings.business_id AND owner_id = auth.uid()));
CREATE POLICY "owners can update own settings" ON public.business_settings FOR UPDATE USING (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_settings.business_id AND owner_id = auth.uid())) WITH CHECK (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_settings.business_id AND owner_id = auth.uid()));
CREATE POLICY "owners can insert own settings" ON public.business_settings FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_settings.business_id AND owner_id = auth.uid()));
CREATE POLICY "owners can delete own settings" ON public.business_settings FOR DELETE USING (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_settings.business_id AND owner_id = auth.uid()));

-- ---------------------------------------------------------------------------
-- Convenience View: admin_business_view (for Ngam Console super admin)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.admin_business_view AS
SELECT
  b.id, b.owner_id, b.trading_name, b.category, b.ssm_number, b.sst_number,
  b.logo_url, b.cover_url, b.address_line, b.postcode, b.city, b.state,
  b.latitude, b.longitude, b.status, b.created_at,
  bc.bank_name, bc.account_holder, bc.account_number, bc.epf_number, bc.socso_number, bc.eis_number,
  bs.operating_hours, bs.is_halal, bs.total_chairs, bs.slot_duration
FROM public.businesses b
LEFT JOIN public.business_compliance bc ON bc.business_id = b.id
LEFT JOIN public.business_settings   bs ON bs.business_id = b.id;
