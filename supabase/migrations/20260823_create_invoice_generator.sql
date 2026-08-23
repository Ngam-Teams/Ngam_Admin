-- Add pg_cron extension if not exists
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

-- Add new columns for transaction volume and payment gateway tracking
ALTER TABLE public.billing_invoices 
ADD COLUMN IF NOT EXISTS transaction_volume INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS gateway_id TEXT;

-- Add a unique constraint to prevent duplicate invoices for the same month
ALTER TABLE public.billing_invoices 
DROP CONSTRAINT IF EXISTS billing_invoices_business_month_key;

ALTER TABLE public.billing_invoices 
ADD CONSTRAINT billing_invoices_business_month_key UNIQUE (business_id, billing_month);

-- Create the invoice generation function
CREATE OR REPLACE FUNCTION public.generate_monthly_invoices(target_date DATE DEFAULT CURRENT_DATE)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    start_of_target_month DATE;
    end_of_target_month DATE;
    business_record RECORD;
    total_volume INT;
    total_fee NUMERIC;
    invoice_is_waived BOOLEAN;
BEGIN
    -- We usually run this on the 1st of the new month to calculate for the PREVIOUS month.
    -- E.g., if run on Sept 1st, we want to calculate for August.
    start_of_target_month := date_trunc('month', target_date - INTERVAL '1 month')::DATE;
    end_of_target_month := (date_trunc('month', target_date) - INTERVAL '1 day')::DATE;

    -- Loop through all active businesses
    FOR business_record IN 
        SELECT id, created_at, status 
        FROM public.businesses 
        WHERE status != 'suspended'
    LOOP
        -- Calculate total fee and volume for this business in the target month
        SELECT 
            COALESCE(SUM(platform_fee_amount), 0),
            COUNT(id)
        INTO total_fee, total_volume
        FROM public.transactions
        WHERE business_id = business_record.id
          AND created_at >= start_of_target_month
          AND created_at < (end_of_target_month + INTERVAL '1 day');
        
        -- Determine if this month falls within their 1-month grace period.
        invoice_is_waived := (start_of_target_month < (business_record.created_at + INTERVAL '1 month'));

        -- If they had transactions, or if we just want to log a zero-invoice, we insert it.
        IF total_fee > 0 THEN
            INSERT INTO public.billing_invoices (
                business_id, 
                billing_month, 
                amount_due, 
                status, 
                is_waived,
                transaction_volume
            ) VALUES (
                business_record.id,
                start_of_target_month,
                CASE WHEN invoice_is_waived THEN 0 ELSE total_fee END,
                CASE WHEN invoice_is_waived THEN 'waived' ELSE 'unpaid' END,
                invoice_is_waived,
                total_volume
            )
            ON CONFLICT (business_id, billing_month) DO NOTHING;
        END IF;

    END LOOP;
END;
$$;

-- Schedule the cron job to run at 00:01 (1 minute past midnight) on the 1st of every month
-- Unschedule first just in case to prevent errors
DO $$
BEGIN
  PERFORM cron.unschedule('generate-monthly-invoices');
EXCEPTION WHEN OTHERS THEN
  -- Ignore if it doesn't exist
END;
$$;

SELECT cron.schedule(
    'generate-monthly-invoices',
    '1 0 1 * *', -- At 00:01 on day-of-month 1
    $$ SELECT public.generate_monthly_invoices(CURRENT_DATE); $$
);
