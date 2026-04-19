
-- Profiles: extra flags
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS loan_applications_allowed BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS transfer_code_1_enabled BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS transfer_code_2_enabled BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS transfer_code_3_enabled BOOLEAN NOT NULL DEFAULT false;

-- account_applications: legacy column names
ALTER TABLE public.account_applications
  ADD COLUMN IF NOT EXISTS reference_number TEXT,
  ADD COLUMN IF NOT EXISTS title TEXT,
  ADD COLUMN IF NOT EXISTS first_name TEXT,
  ADD COLUMN IF NOT EXISTS middle_name TEXT,
  ADD COLUMN IF NOT EXISTS last_name TEXT,
  ADD COLUMN IF NOT EXISTS gender TEXT,
  ADD COLUMN IF NOT EXISTS marital_status TEXT,
  ADD COLUMN IF NOT EXISTS nationality TEXT,
  ADD COLUMN IF NOT EXISTS id_type TEXT,
  ADD COLUMN IF NOT EXISTS id_number TEXT,
  ADD COLUMN IF NOT EXISTS id_expiry_date DATE,
  ADD COLUMN IF NOT EXISTS id_issuing_country TEXT,
  ADD COLUMN IF NOT EXISTS source_of_funds TEXT,
  ADD COLUMN IF NOT EXISTS purpose_of_account TEXT,
  ADD COLUMN IF NOT EXISTS is_pep BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS terms_accepted BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS marketing_consent BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS password_hash TEXT,
  ADD COLUMN IF NOT EXISTS preferred_currency TEXT DEFAULT 'USD',
  ADD COLUMN IF NOT EXISTS initial_deposit NUMERIC(18,2) DEFAULT 0;

UPDATE public.account_applications
  SET reference_number = COALESCE(reference_number, 'APP-' || substr(id::text, 1, 8))
  WHERE reference_number IS NULL;

-- KYC: extra fields
ALTER TABLE public.kyc_documents ADD COLUMN IF NOT EXISTS review_notes TEXT;

-- generate_account_number RPC
CREATE OR REPLACE FUNCTION public.generate_account_number(account_type TEXT)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_num TEXT; v_prefix TEXT;
BEGIN
  v_prefix := CASE account_type WHEN 'savings' THEN '20' WHEN 'business' THEN '30' ELSE '10' END;
  LOOP
    v_num := v_prefix || lpad((floor(random() * 100000000))::text, 8, '0');
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.accounts WHERE account_number = v_num);
  END LOOP;
  RETURN v_num;
END; $$;

-- Rename RPC params (drop+recreate)
DROP FUNCTION IF EXISTS public.admin_approve_deposit(TEXT, UUID, TEXT, TEXT);
CREATE OR REPLACE FUNCTION public.admin_approve_deposit(
  deposit_type TEXT, deposit_id UUID, p_status TEXT, p_notes TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_dep RECORD; v_ref TEXT;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  IF deposit_type = 'crypto' THEN
    SELECT * INTO v_dep FROM public.crypto_deposits WHERE id = deposit_id;
    IF p_status = 'approved' AND v_dep.account_id IS NOT NULL THEN
      v_ref := 'CRY-' || to_char(now(), 'YYYYMMDDHH24MISS');
      INSERT INTO public.transactions (account_id, user_id, transaction_type, amount, description, reference_number, status, category, channel)
        VALUES (v_dep.account_id, v_dep.user_id, 'credit', v_dep.amount_usd, 'Crypto deposit ' || v_dep.crypto_type, v_ref, 'completed', 'deposit', 'crypto');
    END IF;
    UPDATE public.crypto_deposits SET status = p_status, rejection_reason = p_notes, approved_by = auth.uid(), approved_at = now() WHERE id = deposit_id;
  ELSIF deposit_type = 'check' THEN
    SELECT * INTO v_dep FROM public.check_deposits WHERE id = deposit_id;
    IF p_status = 'approved' THEN
      v_ref := 'CHK-' || to_char(now(), 'YYYYMMDDHH24MISS');
      INSERT INTO public.transactions (account_id, user_id, transaction_type, amount, description, reference_number, status, category, channel)
        VALUES (v_dep.account_id, v_dep.user_id, 'credit', v_dep.amount, 'Check deposit', v_ref, 'completed', 'deposit', 'check');
    END IF;
    UPDATE public.check_deposits SET status = p_status, rejection_reason = p_notes, approved_by = auth.uid(), approved_at = now() WHERE id = deposit_id;
  END IF;
  RETURN jsonb_build_object('success', true);
END; $$;

DROP FUNCTION IF EXISTS public.admin_update_transaction(UUID, TEXT, TEXT, NUMERIC);
CREATE OR REPLACE FUNCTION public.admin_update_transaction(
  transaction_id UUID, p_description TEXT DEFAULT NULL, p_status TEXT DEFAULT NULL, p_amount NUMERIC DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  UPDATE public.transactions SET
    description = COALESCE(p_description, description),
    status = COALESCE(p_status, status),
    amount = COALESCE(p_amount, amount)
  WHERE id = transaction_id;
  RETURN jsonb_build_object('success', true);
END; $$;

DROP FUNCTION IF EXISTS public.update_email_template(UUID, TEXT, TEXT, BOOLEAN);
CREATE OR REPLACE FUNCTION public.update_email_template(
  template_id TEXT, p_subject TEXT, p_html TEXT, p_is_active BOOLEAN DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  UPDATE public.email_templates
    SET subject_template = p_subject,
        html_template = p_html,
        is_active = COALESCE(p_is_active, is_active)
    WHERE template_name = template_id OR id::text = template_id;
  RETURN jsonb_build_object('success', true);
END; $$;

DROP FUNCTION IF EXISTS public.get_admin_users_paginated(TEXT, INT, INT);
CREATE OR REPLACE FUNCTION public.get_admin_users_paginated(
  page_number INT DEFAULT 1, p_limit INT DEFAULT 50, p_search TEXT DEFAULT NULL
) RETURNS TABLE(id UUID, email TEXT, full_name TEXT, username TEXT, phone TEXT, account_locked BOOLEAN, created_at TIMESTAMPTZ, total_balance NUMERIC, account_count BIGINT, total_count BIGINT)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v_offset INT;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  v_offset := GREATEST(0, (page_number - 1) * p_limit);
  RETURN QUERY
  WITH filtered AS (
    SELECT p.* FROM public.profiles p
    WHERE p_search IS NULL
      OR p.email ILIKE '%'||p_search||'%'
      OR p.full_name ILIKE '%'||p_search||'%'
      OR p.username ILIKE '%'||p_search||'%'
  ), counted AS (SELECT COUNT(*) AS c FROM filtered)
  SELECT f.id, f.email, f.full_name, f.username, f.phone, f.account_locked, f.created_at,
    COALESCE((SELECT SUM(a.balance) FROM public.accounts a WHERE a.user_id = f.id), 0)::NUMERIC,
    COALESCE((SELECT COUNT(*) FROM public.accounts a WHERE a.user_id = f.id), 0)::BIGINT,
    (SELECT c FROM counted)::BIGINT
  FROM filtered f ORDER BY f.created_at DESC LIMIT p_limit OFFSET v_offset;
END; $$;

DROP FUNCTION IF EXISTS public.set_account_transfer_limit(UUID, NUMERIC);
CREATE OR REPLACE FUNCTION public.set_account_transfer_limit(p_account_id UUID, p_daily_limit NUMERIC)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  UPDATE public.accounts SET transfer_limit = p_daily_limit WHERE id = p_account_id;
  RETURN jsonb_build_object('success', true);
END; $$;

DROP FUNCTION IF EXISTS public.reject_account_application(UUID, TEXT);
CREATE OR REPLACE FUNCTION public.reject_account_application(p_application_id UUID, p_reason TEXT)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  UPDATE public.account_applications SET status = 'rejected', rejection_reason = p_reason, reviewed_by = auth.uid(), reviewed_at = now()
  WHERE id = p_application_id;
  RETURN jsonb_build_object('success', true);
END; $$;

-- Approve transfers: accept p_reference_number too (overload)
DROP FUNCTION IF EXISTS public.approve_external_transfer(UUID);
CREATE OR REPLACE FUNCTION public.approve_external_transfer(p_transaction_id UUID, p_reference_number TEXT DEFAULT NULL)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  UPDATE public.transactions SET status = 'completed' WHERE id = p_transaction_id;
  UPDATE public.transfers SET status = 'approved', approved_by = auth.uid(), approved_at = now() WHERE id = p_transaction_id;
  RETURN jsonb_build_object('success', true);
END; $$;

DROP FUNCTION IF EXISTS public.approve_foreign_remittance(UUID);
CREATE OR REPLACE FUNCTION public.approve_foreign_remittance(remittance_id UUID, p_reference_number TEXT DEFAULT NULL)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_t public.foreign_remittances; v_ref TEXT;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  SELECT * INTO v_t FROM public.foreign_remittances WHERE id = remittance_id;
  v_ref := COALESCE(p_reference_number, 'INT-' || to_char(now(), 'YYYYMMDDHH24MISS'));
  IF v_t.from_account_id IS NOT NULL THEN
    INSERT INTO public.transactions (account_id, user_id, transaction_type, amount, description, reference_number, status, category, channel)
      VALUES (v_t.from_account_id, v_t.user_id, 'debit', v_t.amount + COALESCE(v_t.fee, 0), 'International transfer to '||v_t.recipient_name, v_ref, 'completed', 'transfer', 'international');
  END IF;
  UPDATE public.foreign_remittances SET status = 'approved', approved_by = auth.uid(), approved_at = now() WHERE id = remittance_id;
  RETURN jsonb_build_object('success', true);
END; $$;
