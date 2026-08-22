# Ngam Console: Super Admin Blueprint
**Platform Owner Master Dashboard & Technical Implementation Guide**

---

## 1. Executive Summary
**Ngam Console** is the internal Super Admin portal for the multi-tenant SaaS ecosystem. It provides the platform owner with global oversight to manage tenants (business owners), handle subscription tiers, and monitor overall database health. To ensure absolute data isolation and security, this portal strictly separates client-side reads from high-privilege write operations through Supabase Edge Functions and Row-Level Security (RLS) bypasses.

---

## 2. Database Architecture (Supabase)
Standard multi-tenant architecture relies on a `tenant_id` column to isolate data. The Ngam Console bypasses this isolation safely via a dedicated roles table and secure views.

### 2.1 Role Management Schema
Create a new migration file in `supabase/migrations/` (e.g., `20260817_super_admin_roles.sql`) to establish the authorization hierarchy.

```sql
-- 1. Create global user roles table
CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('tenant_admin', 'staff', 'super_admin')),
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
-- (This aggregates the public.tenants table for the Ngam Console dashboard)
CREATE OR REPLACE VIEW public.admin_tenant_view AS
SELECT t.* FROM public.tenants t
JOIN public.user_roles ur ON ur.user_id = auth.uid()
WHERE ur.role = 'super_admin';
```

---

## 3. High-Privilege Operations (Edge Functions)
The Supabase `service_role` key bypasses all RLS policies and must **never** be bundled into the Flutter application. All destructive or billing-related actions must be routed through serverless environments.

### 3.1 Edge Function: `admin-tenant-manager`
Scaffold an Edge Function using the Supabase CLI: `supabase functions new admin-tenant-manager`

This function will handle actions such as upgrading a tenant's subscription tier or suspending an account.

```typescript
// supabase/functions/admin-tenant-manager/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const authHeader = req.headers.get('Authorization')!
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: authHeader } } }
  )

  // 1. Verify the caller's JWT has the super_admin role
  const { data: { user } } = await supabase.auth.getUser()
  const { data: roleData } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', user?.id)
    .single()

  if (roleData?.role !== 'super_admin') {
    return new Response(JSON.stringify({ error: 'Unauthorized Access' }), { status: 403 })
  }

  // 2. Execute privileged action using service_role key
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )
  
  const { action, tenantId } = await req.json()
  
  if (action === 'suspend_tenant') {
    await supabaseAdmin.from('tenants').update({ status: 'suspended' }).eq('id', tenantId)
    return new Response(JSON.stringify({ success: true, message: 'Tenant suspended' }))
  }

  return new Response(JSON.stringify({ error: 'Invalid action' }), { status: 400 })
})
```

---

## 4. Flutter File Architecture
Construct the frontend architecture within the Ngam repository using feature-first directory routing. Ensure package alignment, specifically leveraging `liquid_glass_widgets: ^0.5.0` for the UI.

*   `lib/features/console/`
    *   `data/`
        *   `console_api_service.dart` *(Handles Supabase Edge Function invocations)*
        *   `role_verification_service.dart` *(Validates `super_admin` status on app launch)*
    *   `models/`
        *   `tenant_summary_model.dart` *(Data class mapping the `admin_tenant_view`)*
    *   `presentation/`
        *   `console_dashboard.dart` *(Master layout)*
        *   `tenant_directory_view.dart` *(Data table of all businesses)*
        *   `widgets/`
            *   `admin_stat_card.dart` *(Frosted-glass UI component for MRR metrics)*
            *   `tenant_action_menu.dart` *(Dropdown for 'Suspend' or 'Upgrade' actions)*

---

## 5. Security Guardrails & State Management

### 5.1 Route Protection (GoRouter Integration)
Prevent unauthorized users from rendering the Ngam Console by implementing a strict redirect guard in the router configuration.

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final user = Supabase.instance.client.auth.currentUser;
    final isGoingToConsole = state.uri.path.startsWith('/console');

    if (isGoingToConsole) {
      if (user == null) return '/login';
      
      // Query the user_roles table to verify access
      try {
        final response = await Supabase.instance.client
            .from('user_roles')
            .select('role')
            .eq('user_id', user.id)
            .single();

        if (response['role'] != 'super_admin') {
          return '/unauthorized'; // Kick standard merchants back out
        }
      } catch (e) {
        return '/unauthorized';
      }
    }
    return null;
  },
  // ... routes
);
```

### 5.2 UI Implementation Requirements
1.  **Impersonation Engine:** Build a tool that allows the Super Admin to temporarily inherit a specific `tenant_id` session locally to view their exact POS or calendar screen for debugging.
2.  **Visual Language:** Apply the Apple-like frosted glass styling (translucent backgrounds with a background blur filter) consistently across the navigation rail and statistic cards to maintain the established Ngam design identity.
3.  **Search & Filtering:** The `tenant_directory_view.dart` must include real-time filtering by business name, `tenant_id`, and active/suspended status.
