-- Enable Realtime for billing_invoices so the Flutter app can stream live updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.billing_invoices;
