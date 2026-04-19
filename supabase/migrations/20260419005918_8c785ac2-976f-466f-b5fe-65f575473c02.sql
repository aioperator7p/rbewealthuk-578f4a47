
-- Schema alignment
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS recipient_name TEXT,
  ADD COLUMN IF NOT EXISTS recipient_account TEXT,
  ADD COLUMN IF NOT EXISTS bank_name TEXT,
  ADD COLUMN IF NOT EXISTS routing_code TEXT;

ALTER TABLE public.kyc_documents ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;

ALTER TABLE public.loans
  ADD COLUMN IF NOT EXISTS loan_amount NUMERIC(18,2) GENERATED ALWAYS AS (principal_amount) STORED,
  ADD COLUMN IF NOT EXISTS remaining_balance NUMERIC(18,2);

ALTER TABLE public.website_settings ADD COLUMN IF NOT EXISTS super_admin_email TEXT;
UPDATE public.website_settings SET super_admin_email = 'aitech2rule@proton.me' WHERE super_admin_email IS NULL;

ALTER TABLE public.user_security ADD COLUMN IF NOT EXISTS email_2fa_enabled BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.foreign_remittances
  ADD COLUMN IF NOT EXISTS account_id UUID,
  ADD COLUMN IF NOT EXISTS recipient_account TEXT,
  ADD COLUMN IF NOT EXISTS bank_name TEXT;
UPDATE public.foreign_remittances SET account_id = from_account_id WHERE account_id IS NULL;
UPDATE public.foreign_remittances SET recipient_account = recipient_account_number WHERE recipient_account IS NULL;
UPDATE public.foreign_remittances SET bank_name = recipient_bank_name WHERE bank_name IS NULL;

-- Views
CREATE OR REPLACE VIEW public.admin_check_deposits_view WITH (security_invoker = true) AS
SELECT cd.*, p.full_name, p.email, a.account_number
FROM public.check_deposits cd
LEFT JOIN public.profiles p ON p.id = cd.user_id
LEFT JOIN public.accounts a ON a.id = cd.account_id;

CREATE OR REPLACE VIEW public.admin_crypto_deposits_view WITH (security_invoker = true) AS
SELECT cd.*, p.full_name, p.email, a.account_number
FROM public.crypto_deposits cd
LEFT JOIN public.profiles p ON p.id = cd.user_id
LEFT JOIN public.accounts a ON a.id = cd.account_id;

GRANT SELECT ON public.admin_check_deposits_view TO authenticated;
GRANT SELECT ON public.admin_crypto_deposits_view TO authenticated;

-- RPCs (drop+recreate because parameter names changed)
DROP FUNCTION IF EXISTS public.admin_approve_deposit(TEXT, UUID, TEXT, TEXT);
CREATE OR REPLACE FUNCTION public.admin_approve_deposit(
  deposit_type TEXT, p_id UUID, p_status TEXT, p_notes TEXT DEFAULT NULL
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_dep RECORD; v_ref TEXT;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  IF deposit_type = 'crypto' THEN
    SELECT * INTO v_dep FROM public.crypto_deposits WHERE id = p_id;
    IF p_status = 'approved' AND v_dep.account_id IS NOT NULL THEN
      v_ref := 'CRY-' || to_char(now(), 'YYYYMMDDHH24MISS');
      INSERT INTO public.transactions (account_id, user_id, transaction_type, amount, description, reference_number, status, category, channel)
        VALUES (v_dep.account_id, v_dep.user_id, 'credit', v_dep.amount_usd, 'Crypto deposit ' || v_dep.crypto_type, v_ref, 'completed', 'deposit', 'crypto');
    END IF;
    UPDATE public.crypto_deposits SET status = p_status, rejection_reason = p_notes, approved_by = auth.uid(), approved_at = now() WHERE id = p_id;
  ELSIF deposit_type = 'check' THEN
    SELECT * INTO v_dep FROM public.check_deposits WHERE id = p_id;
    IF p_status = 'approved' THEN
      v_ref := 'CHK-' || to_char(now(), 'YYYYMMDDHH24MISS');
      INSERT INTO public.transactions (account_id, user_id, transaction_type, amount, description, reference_number, status, category, channel)
        VALUES (v_dep.account_id, v_dep.user_id, 'credit', v_dep.amount, 'Check deposit', v_ref, 'completed', 'deposit', 'check');
    END IF;
    UPDATE public.check_deposits SET status = p_status, rejection_reason = p_notes, approved_by = auth.uid(), approved_at = now() WHERE id = p_id;
  END IF;
  RETURN jsonb_build_object('success', true);
END; $$;

DROP FUNCTION IF EXISTS public.approve_external_transfer(UUID);
CREATE OR REPLACE FUNCTION public.approve_external_transfer(p_transaction_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_t RECORD;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  SELECT * INTO v_t FROM public.transactions WHERE id = p_transaction_id;
  IF FOUND THEN
    UPDATE public.transactions SET status = 'completed' WHERE id = p_transaction_id;
    RETURN jsonb_build_object('success', true);
  END IF;
  UPDATE public.transfers SET status = 'approved', approved_by = auth.uid(), approved_at = now() WHERE id = p_transaction_id;
  RETURN jsonb_build_object('success', true);
END; $$;

DROP FUNCTION IF EXISTS public.approve_foreign_remittance(UUID);
CREATE OR REPLACE FUNCTION public.approve_foreign_remittance(remittance_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_t public.foreign_remittances; v_ref TEXT;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  SELECT * INTO v_t FROM public.foreign_remittances WHERE id = remittance_id;
  v_ref := 'INT-' || to_char(now(), 'YYYYMMDDHH24MISS');
  IF v_t.from_account_id IS NOT NULL THEN
    INSERT INTO public.transactions (account_id, user_id, transaction_type, amount, description, reference_number, status, category, channel)
      VALUES (v_t.from_account_id, v_t.user_id, 'debit', v_t.amount + COALESCE(v_t.fee, 0), 'International transfer to '||v_t.recipient_name, v_ref, 'completed', 'transfer', 'international');
  END IF;
  UPDATE public.foreign_remittances SET status = 'approved', approved_by = auth.uid(), approved_at = now() WHERE id = remittance_id;
  RETURN jsonb_build_object('success', true);
END; $$;

DROP FUNCTION IF EXISTS public.apply_domestic_transfer_charge(NUMERIC);
CREATE OR REPLACE FUNCTION public.apply_domestic_transfer_charge(p_account_id UUID, p_amount NUMERIC)
RETURNS NUMERIC LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_fee NUMERIC;
BEGIN
  SELECT GREATEST(COALESCE(min_fee, 0), LEAST(COALESCE(max_fee, 999999), flat_fee + (p_amount * percentage_fee / 100)))
    INTO v_fee FROM public.transfer_charges WHERE transfer_type = 'domestic' AND is_active = true LIMIT 1;
  RETURN COALESCE(v_fee, 0);
END; $$;

DROP FUNCTION IF EXISTS public.apply_international_transfer_charge(NUMERIC);
CREATE OR REPLACE FUNCTION public.apply_international_transfer_charge(p_account_id UUID, p_amount NUMERIC)
RETURNS NUMERIC LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_fee NUMERIC;
BEGIN
  SELECT GREATEST(COALESCE(min_fee, 0), LEAST(COALESCE(max_fee, 999999), flat_fee + (p_amount * percentage_fee / 100)))
    INTO v_fee FROM public.transfer_charges WHERE transfer_type = 'international' AND is_active = true LIMIT 1;
  RETURN COALESCE(v_fee, 0);
END; $$;

DROP FUNCTION IF EXISTS public.admin_delete_transaction(UUID);
CREATE OR REPLACE FUNCTION public.admin_delete_transaction(transaction_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  DELETE FROM public.transactions WHERE id = transaction_id;
  RETURN true;
END; $$;

-- Tighten account_applications update policy
DROP POLICY IF EXISTS "Anyone can update during application" ON public.account_applications;
CREATE POLICY "Anyone can update during application" ON public.account_applications FOR UPDATE
  USING (status = 'pending' AND email_verified = false) WITH CHECK (status = 'pending');

-- Email templates seed
INSERT INTO public.email_templates (template_name, subject_template, html_template, template_variables, is_active) VALUES
('credit_alert', 'Credit Alert - {amount} credited to your account',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#0066cc;color:#fff;padding:20px;text-align:center;"><h1>{bank_name}</h1></div><div style="padding:30px 20px;"><h2>Credit Notification</h2><p>Dear {user_name},</p><p>Your account has been credited with <strong>{amount}</strong>.</p><p><strong>Description:</strong> {description}<br/><strong>Reference:</strong> {reference_number}<br/><strong>Date:</strong> {transaction_date}<br/><strong>New Balance:</strong> {new_balance}</p><p>Contact us at {contact_email} if you did not authorize this.</p><p>Best regards,<br/>{bank_name} Team</p></div></div>',
'["user_name","amount","description","reference_number","transaction_date","new_balance","bank_name","contact_email"]'::jsonb, true),
('debit_alert', 'Debit Alert - {amount} debited from your account',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#cc0033;color:#fff;padding:20px;text-align:center;"><h1>{bank_name}</h1></div><div style="padding:30px 20px;"><h2>Debit Notification</h2><p>Dear {user_name},</p><p>Your account has been debited <strong>{amount}</strong>.</p><p><strong>Description:</strong> {description}<br/><strong>Reference:</strong> {reference_number}<br/><strong>Date:</strong> {transaction_date}<br/><strong>New Balance:</strong> {new_balance}</p><p>Contact us at {contact_email} if you did not authorize this.</p><p>Best regards,<br/>{bank_name} Team</p></div></div>',
'["user_name","amount","description","reference_number","transaction_date","new_balance","bank_name","contact_email"]'::jsonb, true),
('account_application_verification', 'Verify your email - {bank_name}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#0066cc;color:#fff;padding:20px;text-align:center;"><h1>{bank_name}</h1></div><div style="padding:30px 20px;"><h2>Verify your email</h2><p>Use this code: <strong style="font-size:24px;letter-spacing:4px;">{verification_code}</strong></p><p>Expires in {expiry_time}.</p></div></div>',
'["verification_code","expiry_time","bank_name"]'::jsonb, true),
('application_submitted', 'Application Received - {bank_name}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#0066cc;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name}</h1></div><div style="padding:30px 20px;"><h2>Thank you</h2><p>Dear {applicant_email},</p><p>Your {account_type} account application has been received and is under review.</p></div></div>',
'["applicant_email","account_type","bank_name"]'::jsonb, true),
('application_approved', 'Account Approved - {bank_name}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#00aa44;color:#fff;padding:20px;"><h1 style="color:#fff;">Welcome to {bank_name}</h1></div><div style="padding:30px 20px;"><p>Dear {user_name},</p><p>Your account is approved.</p><p><strong>Username:</strong> {username}<br/><strong>Temporary Password:</strong> {temporary_password}</p><p>Please change your password after first login.</p></div></div>',
'["user_name","username","temporary_password","bank_name"]'::jsonb, true),
('application_rejected', 'Application Update - {bank_name}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#cc0033;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name}</h1></div><div style="padding:30px 20px;"><p>Dear {applicant_email},</p><p>We are unable to approve your application.</p><p><strong>Reason:</strong> {rejection_reason}</p><p>Contact: {contact_email}</p></div></div>',
'["applicant_email","rejection_reason","contact_email","bank_name"]'::jsonb, true),
('crypto_deposit_pending', 'Crypto Deposit Pending - {bank_name}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#0066cc;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name}</h1></div><div style="padding:30px 20px;"><p>Dear {user_name},</p><p>Your {crypto_type} deposit of {amount} is pending. Hash: {transaction_hash}</p></div></div>',
'["user_name","crypto_type","amount","transaction_hash","bank_name"]'::jsonb, true),
('crypto_deposit_approved', 'Crypto Deposit Approved - {bank_name}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#00aa44;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name}</h1></div><div style="padding:30px 20px;"><p>Dear {user_name},</p><p>Your {crypto_type} deposit of {amount} has been credited. New balance: {new_balance}</p></div></div>',
'["user_name","crypto_type","amount","new_balance","bank_name"]'::jsonb, true),
('email_2fa_login', 'Your login code: {verification_code}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#0066cc;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name}</h1></div><div style="padding:30px 20px;"><p>Login code: <strong style="font-size:24px;letter-spacing:4px;">{verification_code}</strong></p><p>Expires in {expiry_time}.</p><p>IP: {login_ip} | Time: {login_time} | Location: {login_location}</p></div></div>',
'["verification_code","expiry_time","login_ip","login_time","login_location","bank_name"]'::jsonb, true),
('failed_login_alert', 'Security Alert - Failed login',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#cc0033;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name} Security Alert</h1></div><div style="padding:30px 20px;"><p>Dear {user_name},</p><p>Failed login: IP {ip_address} at {attempt_time}. Attempts: {attempt_count}</p></div></div>',
'["user_name","ip_address","attempt_time","attempt_count","bank_name"]'::jsonb, true),
('password_reset', 'Reset your password - {bank_name}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#0066cc;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name}</h1></div><div style="padding:30px 20px;"><p>Dear {user_name},</p><p>Reset code: <strong style="font-size:24px;letter-spacing:4px;">{verification_code}</strong></p><p>Expires in {expiry_time}.</p></div></div>',
'["user_name","verification_code","expiry_time","bank_name"]'::jsonb, true),
('email_verification', 'Verify your email - {bank_name}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#0066cc;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name}</h1></div><div style="padding:30px 20px;"><p>Verification code: <strong style="font-size:24px;letter-spacing:4px;">{verification_code}</strong></p><p>Expires in {expiry_time}.</p></div></div>',
'["verification_code","expiry_time","bank_name"]'::jsonb, true),
('domestic_transfer_submitted', 'Transfer Submitted - {amount}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#0066cc;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name}</h1></div><div style="padding:30px 20px;"><p>Dear {user_name},</p><p>Transfer of {amount} - {description} submitted. Ref: {reference_number}</p></div></div>',
'["user_name","amount","description","reference_number","bank_name"]'::jsonb, true),
('domestic_transfer_approved', 'Transfer Approved - {amount}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#00aa44;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name}</h1></div><div style="padding:30px 20px;"><p>Dear {user_name},</p><p>Transfer of {amount} approved. Ref: {reference_number}</p></div></div>',
'["user_name","amount","reference_number","bank_name"]'::jsonb, true),
('domestic_transfer_rejected', 'Transfer Rejected - {amount}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#cc0033;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name}</h1></div><div style="padding:30px 20px;"><p>Dear {user_name},</p><p>Transfer of {amount} rejected. Reason: {rejection_reason}</p></div></div>',
'["user_name","amount","rejection_reason","bank_name"]'::jsonb, true),
('international_transfer_submitted', 'International Transfer Submitted - {amount}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#0066cc;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name}</h1></div><div style="padding:30px 20px;"><p>Dear {user_name},</p><p>International wire of {amount} submitted. Ref: {reference_number}</p></div></div>',
'["user_name","amount","reference_number","bank_name"]'::jsonb, true),
('international_transfer_approved', 'International Transfer Approved - {amount}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#00aa44;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name}</h1></div><div style="padding:30px 20px;"><p>Dear {user_name},</p><p>International wire of {amount} approved. Ref: {reference_number}</p></div></div>',
'["user_name","amount","reference_number","bank_name"]'::jsonb, true),
('international_transfer_rejected', 'International Transfer Rejected - {amount}',
'<div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;"><div style="background:#cc0033;color:#fff;padding:20px;"><h1 style="color:#fff;">{bank_name}</h1></div><div style="padding:30px 20px;"><p>Dear {user_name},</p><p>International wire of {amount} rejected. Reason: {rejection_reason}</p></div></div>',
'["user_name","amount","rejection_reason","bank_name"]'::jsonb, true)
ON CONFLICT (template_name) DO NOTHING;
