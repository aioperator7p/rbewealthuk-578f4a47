
-- ============================================================================
-- WYSEFORTE BANK — COMPREHENSIVE BACKEND SCHEMA
-- ============================================================================

-- Helper: updated_at trigger (already exists, but ensure)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

-- ============================================================================
-- ACCOUNTS
-- ============================================================================
CREATE TABLE public.accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  account_number TEXT NOT NULL UNIQUE,
  account_type TEXT NOT NULL DEFAULT 'checking',
  balance NUMERIC(18,2) NOT NULL DEFAULT 0,
  available_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'USD',
  status TEXT NOT NULL DEFAULT 'active',
  transfer_limit NUMERIC(18,2) NOT NULL DEFAULT 50000,
  transfer_blocked BOOLEAN NOT NULL DEFAULT false,
  routing_number TEXT,
  swift_code TEXT,
  iban TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own accounts" ON public.accounts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users update own accounts" ON public.accounts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Admins manage accounts" ON public.accounts FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_accounts_updated BEFORE UPDATE ON public.accounts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE INDEX idx_accounts_user ON public.accounts(user_id);

-- ============================================================================
-- TRANSACTIONS
-- ============================================================================
CREATE TABLE public.transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  transaction_type TEXT NOT NULL, -- credit | debit
  amount NUMERIC(18,2) NOT NULL,
  description TEXT,
  reference_number TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'completed',
  balance_after NUMERIC(18,2),
  category TEXT,
  channel TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own transactions" ON public.transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins manage transactions" ON public.transactions FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_transactions_updated BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE INDEX idx_tx_account ON public.transactions(account_id);
CREATE INDEX idx_tx_user ON public.transactions(user_id);
CREATE INDEX idx_tx_created ON public.transactions(created_at DESC);

-- Trigger: maintain account balance on transaction insert
CREATE OR REPLACE FUNCTION public.apply_transaction_to_balance()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_new_balance NUMERIC(18,2);
BEGIN
  IF NEW.status = 'completed' THEN
    IF NEW.transaction_type = 'credit' THEN
      UPDATE public.accounts SET balance = balance + NEW.amount, available_balance = available_balance + NEW.amount WHERE id = NEW.account_id RETURNING balance INTO v_new_balance;
    ELSE
      UPDATE public.accounts SET balance = balance - NEW.amount, available_balance = available_balance - NEW.amount WHERE id = NEW.account_id RETURNING balance INTO v_new_balance;
    END IF;
    NEW.balance_after := v_new_balance;
  END IF;
  RETURN NEW;
END; $$;
CREATE TRIGGER trg_apply_tx BEFORE INSERT ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.apply_transaction_to_balance();

-- ============================================================================
-- TRANSFERS (domestic external)
-- ============================================================================
CREATE TABLE public.transfers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  from_account_id UUID REFERENCES public.accounts(id) ON DELETE SET NULL,
  recipient_name TEXT NOT NULL,
  recipient_account_number TEXT NOT NULL,
  recipient_bank TEXT,
  recipient_routing TEXT,
  amount NUMERIC(18,2) NOT NULL,
  fee NUMERIC(18,2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'USD',
  description TEXT,
  reference_number TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'pending',
  transfer_type TEXT NOT NULL DEFAULT 'domestic',
  rejection_reason TEXT,
  approved_by UUID,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.transfers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own transfers" ON public.transfers FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own transfers" ON public.transfers FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage transfers" ON public.transfers FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_transfers_updated BEFORE UPDATE ON public.transfers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- FOREIGN REMITTANCES
-- ============================================================================
CREATE TABLE public.foreign_remittances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  from_account_id UUID REFERENCES public.accounts(id) ON DELETE SET NULL,
  recipient_name TEXT NOT NULL,
  recipient_address TEXT,
  recipient_country TEXT NOT NULL,
  recipient_bank_name TEXT NOT NULL,
  recipient_bank_address TEXT,
  recipient_account_number TEXT NOT NULL,
  swift_code TEXT NOT NULL,
  iban TEXT,
  amount NUMERIC(18,2) NOT NULL,
  fee NUMERIC(18,2) NOT NULL DEFAULT 0,
  exchange_rate NUMERIC(18,6),
  currency TEXT NOT NULL DEFAULT 'USD',
  recipient_currency TEXT NOT NULL DEFAULT 'USD',
  purpose TEXT,
  reference_number TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  approved_by UUID,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.foreign_remittances ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own remittances" ON public.foreign_remittances FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own remittances" ON public.foreign_remittances FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage remittances" ON public.foreign_remittances FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_remit_updated BEFORE UPDATE ON public.foreign_remittances FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- PAYEES
-- ============================================================================
CREATE TABLE public.payees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name TEXT NOT NULL,
  account_number TEXT NOT NULL,
  bank_name TEXT,
  routing_number TEXT,
  swift_code TEXT,
  country TEXT,
  payee_type TEXT DEFAULT 'domestic',
  nickname TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.payees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own payees" ON public.payees FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins view payees" ON public.payees FOR SELECT USING (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_payees_updated BEFORE UPDATE ON public.payees FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- BILL PAYMENTS
-- ============================================================================
CREATE TABLE public.bill_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  biller_name TEXT NOT NULL,
  biller_account TEXT,
  category TEXT,
  amount NUMERIC(18,2) NOT NULL,
  reference_number TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'completed',
  scheduled_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.bill_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own bills" ON public.bill_payments FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins view bills" ON public.bill_payments FOR SELECT USING (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_bills_updated BEFORE UPDATE ON public.bill_payments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- ACCOUNT STATEMENTS
-- ============================================================================
CREATE TABLE public.account_statements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  statement_period_start DATE NOT NULL,
  statement_period_end DATE NOT NULL,
  statement_type TEXT NOT NULL DEFAULT 'monthly',
  opening_balance NUMERIC(18,2),
  closing_balance NUMERIC(18,2),
  total_credits NUMERIC(18,2) DEFAULT 0,
  total_debits NUMERIC(18,2) DEFAULT 0,
  transaction_count INTEGER DEFAULT 0,
  file_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.account_statements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own statements" ON public.account_statements FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users create own statements" ON public.account_statements FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage statements" ON public.account_statements FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));

-- ============================================================================
-- KYC DOCUMENTS
-- ============================================================================
CREATE TABLE public.kyc_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  document_type TEXT NOT NULL,
  document_number TEXT,
  file_url TEXT NOT NULL,
  file_name TEXT,
  verification_status TEXT NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  verified_by UUID,
  verified_at TIMESTAMPTZ,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  metadata JSONB DEFAULT '{}'::jsonb
);
ALTER TABLE public.kyc_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own kyc" ON public.kyc_documents FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users upload own kyc" ON public.kyc_documents FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage kyc" ON public.kyc_documents FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));

-- ============================================================================
-- LOAN INTEREST RATES
-- ============================================================================
CREATE TABLE public.loan_interest_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_type TEXT NOT NULL UNIQUE,
  interest_rate NUMERIC(5,2) NOT NULL,
  min_amount NUMERIC(18,2) DEFAULT 0,
  max_amount NUMERIC(18,2),
  min_term_months INTEGER DEFAULT 1,
  max_term_months INTEGER DEFAULT 360,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.loan_interest_rates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view active rates" ON public.loan_interest_rates FOR SELECT USING (is_active = true);
CREATE POLICY "Admins manage rates" ON public.loan_interest_rates FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_rates_updated BEFORE UPDATE ON public.loan_interest_rates FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

INSERT INTO public.loan_interest_rates (loan_type, interest_rate, min_amount, max_amount) VALUES
('personal', 7.5, 1000, 50000),
('auto', 5.5, 5000, 100000),
('mortgage', 4.5, 50000, 1000000),
('business', 8.0, 5000, 500000);

-- ============================================================================
-- LOAN APPLICATIONS
-- ============================================================================
CREATE TABLE public.loan_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  loan_type TEXT NOT NULL,
  requested_amount NUMERIC(18,2) NOT NULL,
  term_months INTEGER NOT NULL,
  purpose TEXT,
  monthly_income NUMERIC(18,2),
  employment_status TEXT,
  employer_name TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  reviewed_by UUID,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.loan_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own loan apps" ON public.loan_applications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users create own loan apps" ON public.loan_applications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage loan apps" ON public.loan_applications FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_loanapp_updated BEFORE UPDATE ON public.loan_applications FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- LOANS (approved/disbursed)
-- ============================================================================
CREATE TABLE public.loans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES public.loan_applications(id) ON DELETE SET NULL,
  user_id UUID NOT NULL,
  account_id UUID REFERENCES public.accounts(id) ON DELETE SET NULL,
  loan_type TEXT NOT NULL,
  principal_amount NUMERIC(18,2) NOT NULL,
  interest_rate NUMERIC(5,2) NOT NULL,
  term_months INTEGER NOT NULL,
  monthly_payment NUMERIC(18,2),
  outstanding_balance NUMERIC(18,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  disbursed_at TIMESTAMPTZ,
  next_payment_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own loans" ON public.loans FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins manage loans" ON public.loans FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_loans_updated BEFORE UPDATE ON public.loans FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- LOAN PAYMENTS
-- ============================================================================
CREATE TABLE public.loan_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id UUID NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  amount NUMERIC(18,2) NOT NULL,
  principal_portion NUMERIC(18,2),
  interest_portion NUMERIC(18,2),
  payment_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'paid',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.loan_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own loan payments" ON public.loan_payments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins manage loan payments" ON public.loan_payments FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));

-- ============================================================================
-- TRANSFER CHARGES
-- ============================================================================
CREATE TABLE public.transfer_charges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transfer_type TEXT NOT NULL UNIQUE,
  flat_fee NUMERIC(18,2) NOT NULL DEFAULT 0,
  percentage_fee NUMERIC(5,2) NOT NULL DEFAULT 0,
  min_fee NUMERIC(18,2) DEFAULT 0,
  max_fee NUMERIC(18,2),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.transfer_charges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone view active charges" ON public.transfer_charges FOR SELECT USING (is_active = true);
CREATE POLICY "Admins manage charges" ON public.transfer_charges FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_charges_updated BEFORE UPDATE ON public.transfer_charges FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

INSERT INTO public.transfer_charges (transfer_type, flat_fee, percentage_fee, min_fee, max_fee) VALUES
('intrabank', 0, 0, 0, 0),
('domestic', 5, 0.5, 5, 50),
('international', 25, 1.0, 25, 200);

-- ============================================================================
-- SUPPORT TICKETS
-- ============================================================================
CREATE TABLE public.support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  ticket_number TEXT NOT NULL UNIQUE,
  subject TEXT NOT NULL,
  message TEXT NOT NULL,
  category TEXT DEFAULT 'general',
  priority TEXT DEFAULT 'normal',
  status TEXT NOT NULL DEFAULT 'open',
  admin_response TEXT,
  responded_by UUID,
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own tickets" ON public.support_tickets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users create tickets" ON public.support_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage tickets" ON public.support_tickets FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_tickets_updated BEFORE UPDATE ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- ACCOUNT APPLICATIONS (pre-signup)
-- ============================================================================
CREATE TABLE public.account_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT,
  date_of_birth DATE,
  address TEXT,
  city TEXT,
  state TEXT,
  postal_code TEXT,
  country TEXT,
  account_type TEXT DEFAULT 'checking',
  username TEXT,
  ssn_last_four TEXT,
  occupation TEXT,
  employer TEXT,
  annual_income NUMERIC(18,2),
  id_document_url TEXT,
  proof_of_address_url TEXT,
  selfie_url TEXT,
  verification_code TEXT,
  verification_code_expires_at TIMESTAMPTZ,
  email_verified BOOLEAN NOT NULL DEFAULT false,
  status TEXT NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  reviewed_by UUID,
  reviewed_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.account_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can apply" ON public.account_applications FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can view by email" ON public.account_applications FOR SELECT USING (true);
CREATE POLICY "Anyone can update during application" ON public.account_applications FOR UPDATE USING (true);
CREATE POLICY "Admins manage applications" ON public.account_applications FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_app_updated BEFORE UPDATE ON public.account_applications FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE INDEX idx_app_email ON public.account_applications(email);
CREATE INDEX idx_app_username ON public.account_applications(username);

-- ============================================================================
-- NEXT OF KIN
-- ============================================================================
CREATE TABLE public.next_of_kin (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  relationship TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.next_of_kin ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own kin" ON public.next_of_kin FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins view kin" ON public.next_of_kin FOR SELECT USING (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_kin_updated BEFORE UPDATE ON public.next_of_kin FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  notification_type TEXT DEFAULT 'info',
  is_read BOOLEAN NOT NULL DEFAULT false,
  link TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Admins manage notifications" ON public.notifications FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE INDEX idx_notif_user ON public.notifications(user_id, created_at DESC);

-- ============================================================================
-- USER SECURITY
-- ============================================================================
CREATE TABLE public.user_security (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE,
  two_fa_enabled BOOLEAN NOT NULL DEFAULT false,
  security_code TEXT,
  security_code_enabled BOOLEAN NOT NULL DEFAULT false,
  security_question TEXT,
  security_answer_hash TEXT,
  failed_login_attempts INTEGER NOT NULL DEFAULT 0,
  locked_until TIMESTAMPTZ,
  last_login_at TIMESTAMPTZ,
  last_login_ip TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.user_security ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own security" ON public.user_security FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users update own security" ON public.user_security FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users insert own security" ON public.user_security FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage security" ON public.user_security FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_sec_updated BEFORE UPDATE ON public.user_security FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- WEBSITE SETTINGS
-- ============================================================================
CREATE TABLE public.website_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_name TEXT NOT NULL DEFAULT 'Wyseforte Bank',
  bank_short_name TEXT DEFAULT 'Wyseforte',
  bank_address TEXT DEFAULT '1 Wyseforte Plaza, London, UK',
  bank_email TEXT DEFAULT 'support@wyseforte.com',
  contact_email TEXT DEFAULT 'contact@wyseforte.com',
  bank_phone TEXT DEFAULT '+44 20 0000 0000',
  logo_url TEXT,
  favicon_url TEXT,
  primary_color TEXT DEFAULT '#0066cc',
  secondary_color TEXT DEFAULT '#003366',
  social_facebook TEXT,
  social_twitter TEXT,
  social_linkedin TEXT,
  social_instagram TEXT,
  smtp_host TEXT,
  smtp_port INTEGER,
  smtp_user TEXT,
  smtp_password TEXT,
  smtp_from_email TEXT,
  smtp_from_name TEXT,
  maintenance_mode BOOLEAN NOT NULL DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.website_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone view settings" ON public.website_settings FOR SELECT USING (true);
CREATE POLICY "Admins manage settings" ON public.website_settings FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_settings_updated BEFORE UPDATE ON public.website_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

INSERT INTO public.website_settings (bank_name) VALUES ('Wyseforte Bank');

-- ============================================================================
-- EMAIL TEMPLATES
-- ============================================================================
CREATE TABLE public.email_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_name TEXT NOT NULL UNIQUE,
  subject_template TEXT NOT NULL,
  html_template TEXT NOT NULL,
  template_variables JSONB DEFAULT '[]'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.email_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone view active templates" ON public.email_templates FOR SELECT USING (is_active = true OR has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins manage templates" ON public.email_templates FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_tpl_updated BEFORE UPDATE ON public.email_templates FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- CRYPTO DEPOSIT CONFIG + DEPOSITS
-- ============================================================================
CREATE TABLE public.crypto_deposit_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crypto_type TEXT NOT NULL UNIQUE,
  wallet_address TEXT NOT NULL,
  network TEXT,
  qr_code_url TEXT,
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  min_deposit NUMERIC(18,8) DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.crypto_deposit_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone view enabled crypto" ON public.crypto_deposit_config FOR SELECT USING (is_enabled = true OR has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins manage crypto config" ON public.crypto_deposit_config FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_crypto_cfg_updated BEFORE UPDATE ON public.crypto_deposit_config FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.crypto_deposits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  account_id UUID REFERENCES public.accounts(id) ON DELETE SET NULL,
  crypto_type TEXT NOT NULL,
  amount_crypto NUMERIC(18,8) NOT NULL,
  amount_usd NUMERIC(18,2) NOT NULL,
  transaction_hash TEXT,
  wallet_address TEXT,
  proof_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  approved_by UUID,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.crypto_deposits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own crypto" ON public.crypto_deposits FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users create crypto" ON public.crypto_deposits FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage crypto" ON public.crypto_deposits FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_crypto_updated BEFORE UPDATE ON public.crypto_deposits FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- CHECK DEPOSITS
-- ============================================================================
CREATE TABLE public.check_deposits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  amount NUMERIC(18,2) NOT NULL,
  check_number TEXT,
  front_image_url TEXT,
  back_image_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  rejection_reason TEXT,
  approved_by UUID,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.check_deposits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own checks" ON public.check_deposits FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users create checks" ON public.check_deposits FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage checks" ON public.check_deposits FOR ALL USING (has_role(auth.uid(), 'admin')) WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE TRIGGER trg_check_updated BEFORE UPDATE ON public.check_deposits FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- ADMIN AUDIT LOGS
-- ============================================================================
CREATE TABLE public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins view audit logs" ON public.admin_audit_logs FOR SELECT USING (has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins insert audit logs" ON public.admin_audit_logs FOR INSERT WITH CHECK (has_role(auth.uid(), 'admin'));
CREATE INDEX idx_audit_created ON public.admin_audit_logs(created_at DESC);

-- ============================================================================
-- AUTO-CREATE DEFAULT ACCOUNT ON PROFILE CREATE
-- ============================================================================
CREATE OR REPLACE FUNCTION public.create_default_account_for_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_acct_num TEXT;
BEGIN
  v_acct_num := lpad((floor(random() * 9000000000) + 1000000000)::text, 10, '0');
  INSERT INTO public.accounts (user_id, account_number, account_type, balance, available_balance)
  VALUES (NEW.id, v_acct_num, 'checking', 0, 0)
  ON CONFLICT DO NOTHING;
  INSERT INTO public.user_security (user_id) VALUES (NEW.id) ON CONFLICT DO NOTHING;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_default_account ON public.profiles;
CREATE TRIGGER trg_default_account AFTER INSERT ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.create_default_account_for_user();

-- Backfill default account & security for existing admin profile
INSERT INTO public.accounts (user_id, account_number, account_type, balance, available_balance)
SELECT p.id, lpad((floor(random() * 9000000000) + 1000000000)::text, 10, '0'), 'checking', 0, 0
FROM public.profiles p
LEFT JOIN public.accounts a ON a.user_id = p.id
WHERE a.id IS NULL;

INSERT INTO public.user_security (user_id)
SELECT p.id FROM public.profiles p
LEFT JOIN public.user_security s ON s.user_id = p.id
WHERE s.id IS NULL;

-- Ensure new auth users trigger fires and creates handle
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- RPC FUNCTIONS
-- ============================================================================

-- Email templates
CREATE OR REPLACE FUNCTION public.get_email_templates()
RETURNS SETOF public.email_templates LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT * FROM public.email_templates ORDER BY template_name;
$$;

CREATE OR REPLACE FUNCTION public.update_email_template(
  p_id UUID, p_subject TEXT, p_html TEXT, p_is_active BOOLEAN DEFAULT NULL
) RETURNS public.email_templates LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_row public.email_templates;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  UPDATE public.email_templates
    SET subject_template = p_subject,
        html_template = p_html,
        is_active = COALESCE(p_is_active, is_active)
    WHERE id = p_id RETURNING * INTO v_row;
  RETURN v_row;
END; $$;

-- Website settings
CREATE OR REPLACE FUNCTION public.get_website_settings()
RETURNS public.website_settings LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT * FROM public.website_settings ORDER BY created_at LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_public_website_settings()
RETURNS TABLE(bank_name TEXT, bank_short_name TEXT, logo_url TEXT, favicon_url TEXT, primary_color TEXT, secondary_color TEXT, contact_email TEXT, bank_phone TEXT, bank_address TEXT, social_facebook TEXT, social_twitter TEXT, social_linkedin TEXT, social_instagram TEXT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT bank_name, bank_short_name, logo_url, favicon_url, primary_color, secondary_color, contact_email, bank_phone, bank_address, social_facebook, social_twitter, social_linkedin, social_instagram
  FROM public.website_settings ORDER BY created_at LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.update_website_settings(p_settings JSONB)
RETURNS public.website_settings LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_row public.website_settings; v_id UUID;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  SELECT id INTO v_id FROM public.website_settings ORDER BY created_at LIMIT 1;
  UPDATE public.website_settings SET
    bank_name = COALESCE(p_settings->>'bank_name', bank_name),
    bank_short_name = COALESCE(p_settings->>'bank_short_name', bank_short_name),
    bank_address = COALESCE(p_settings->>'bank_address', bank_address),
    bank_email = COALESCE(p_settings->>'bank_email', bank_email),
    contact_email = COALESCE(p_settings->>'contact_email', contact_email),
    bank_phone = COALESCE(p_settings->>'bank_phone', bank_phone),
    logo_url = COALESCE(p_settings->>'logo_url', logo_url),
    favicon_url = COALESCE(p_settings->>'favicon_url', favicon_url),
    primary_color = COALESCE(p_settings->>'primary_color', primary_color),
    secondary_color = COALESCE(p_settings->>'secondary_color', secondary_color),
    social_facebook = COALESCE(p_settings->>'social_facebook', social_facebook),
    social_twitter = COALESCE(p_settings->>'social_twitter', social_twitter),
    social_linkedin = COALESCE(p_settings->>'social_linkedin', social_linkedin),
    social_instagram = COALESCE(p_settings->>'social_instagram', social_instagram),
    smtp_host = COALESCE(p_settings->>'smtp_host', smtp_host),
    smtp_port = COALESCE((p_settings->>'smtp_port')::int, smtp_port),
    smtp_user = COALESCE(p_settings->>'smtp_user', smtp_user),
    smtp_password = COALESCE(p_settings->>'smtp_password', smtp_password),
    smtp_from_email = COALESCE(p_settings->>'smtp_from_email', smtp_from_email),
    smtp_from_name = COALESCE(p_settings->>'smtp_from_name', smtp_from_name)
  WHERE id = v_id RETURNING * INTO v_row;
  RETURN v_row;
END; $$;

-- Admin notification counts
CREATE OR REPLACE FUNCTION public.get_admin_notification_counts()
RETURNS JSONB LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE v JSONB;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  SELECT jsonb_build_object(
    'pending_applications', (SELECT COUNT(*) FROM public.account_applications WHERE status = 'pending'),
    'pending_kyc', (SELECT COUNT(*) FROM public.kyc_documents WHERE verification_status = 'pending'),
    'pending_loans', (SELECT COUNT(*) FROM public.loan_applications WHERE status = 'pending'),
    'pending_transfers', (SELECT COUNT(*) FROM public.transfers WHERE status = 'pending'),
    'pending_remittances', (SELECT COUNT(*) FROM public.foreign_remittances WHERE status = 'pending'),
    'pending_crypto', (SELECT COUNT(*) FROM public.crypto_deposits WHERE status = 'pending'),
    'open_tickets', (SELECT COUNT(*) FROM public.support_tickets WHERE status = 'open')
  ) INTO v;
  RETURN v;
END; $$;

-- Paginated user list for admin
CREATE OR REPLACE FUNCTION public.get_admin_users_paginated(
  p_search TEXT DEFAULT NULL, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0
) RETURNS TABLE(id UUID, email TEXT, full_name TEXT, username TEXT, phone TEXT, account_locked BOOLEAN, created_at TIMESTAMPTZ, total_balance NUMERIC, account_count BIGINT, total_count BIGINT)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
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
  FROM filtered f ORDER BY f.created_at DESC LIMIT p_limit OFFSET p_offset;
END; $$;

-- Admin transactions
CREATE OR REPLACE FUNCTION public.admin_create_transaction(
  p_account_id UUID, p_type TEXT, p_amount NUMERIC, p_description TEXT, p_category TEXT DEFAULT 'manual'
) RETURNS public.transactions LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_row public.transactions; v_user UUID; v_ref TEXT;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  SELECT user_id INTO v_user FROM public.accounts WHERE id = p_account_id;
  v_ref := 'ADM-' || to_char(now(), 'YYYYMMDDHH24MISS') || '-' || substr(md5(random()::text), 1, 6);
  INSERT INTO public.transactions (account_id, user_id, transaction_type, amount, description, reference_number, status, category, channel)
    VALUES (p_account_id, v_user, p_type, p_amount, p_description, v_ref, 'completed', p_category, 'admin')
    RETURNING * INTO v_row;
  RETURN v_row;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_update_transaction(
  p_id UUID, p_description TEXT DEFAULT NULL, p_status TEXT DEFAULT NULL, p_amount NUMERIC DEFAULT NULL
) RETURNS public.transactions LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_row public.transactions;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  UPDATE public.transactions SET
    description = COALESCE(p_description, description),
    status = COALESCE(p_status, status),
    amount = COALESCE(p_amount, amount)
  WHERE id = p_id RETURNING * INTO v_row;
  RETURN v_row;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_delete_transaction(p_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  DELETE FROM public.transactions WHERE id = p_id;
  RETURN true;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_delete_account(p_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  DELETE FROM public.accounts WHERE id = p_id;
  RETURN true;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_clear_security_lock(p_user_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  UPDATE public.user_security SET failed_login_attempts = 0, locked_until = NULL WHERE user_id = p_user_id;
  UPDATE public.profiles SET account_locked = false WHERE id = p_user_id;
  RETURN true;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_disable_security_code(p_user_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  UPDATE public.user_security SET security_code_enabled = false, security_code = NULL WHERE user_id = p_user_id;
  RETURN true;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_toggle_account_transfer_block(p_account_id UUID)
RETURNS public.accounts LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_row public.accounts;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  UPDATE public.accounts SET transfer_blocked = NOT transfer_blocked WHERE id = p_account_id RETURNING * INTO v_row;
  RETURN v_row;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_approve_loan_with_disbursement(p_loan_id UUID)
RETURNS public.loans LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_loan public.loans; v_acct UUID; v_ref TEXT;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  SELECT * INTO v_loan FROM public.loans WHERE id = p_loan_id;
  IF v_loan.account_id IS NULL THEN
    SELECT id INTO v_acct FROM public.accounts WHERE user_id = v_loan.user_id LIMIT 1;
    UPDATE public.loans SET account_id = v_acct WHERE id = p_loan_id;
    v_loan.account_id := v_acct;
  END IF;
  v_ref := 'LOAN-' || to_char(now(), 'YYYYMMDDHH24MISS');
  INSERT INTO public.transactions (account_id, user_id, transaction_type, amount, description, reference_number, status, category)
    VALUES (v_loan.account_id, v_loan.user_id, 'credit', v_loan.principal_amount, 'Loan disbursement', v_ref, 'completed', 'loan');
  UPDATE public.loans SET status = 'active', disbursed_at = now() WHERE id = p_loan_id RETURNING * INTO v_loan;
  RETURN v_loan;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_delete_loan(p_loan_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  DELETE FROM public.loans WHERE id = p_loan_id;
  RETURN true;
END; $$;

-- Intra-bank
CREATE OR REPLACE FUNCTION public.lookup_intrabank_recipient(p_account_number TEXT)
RETURNS TABLE(account_id UUID, user_id UUID, full_name TEXT, account_number TEXT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT a.id, a.user_id, p.full_name, a.account_number
  FROM public.accounts a JOIN public.profiles p ON p.id = a.user_id
  WHERE a.account_number = p_account_number AND a.status = 'active' LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.process_intrabank_transfer(
  p_from_account UUID, p_to_account_number TEXT, p_amount NUMERIC, p_description TEXT
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_from public.accounts; v_to public.accounts; v_ref TEXT;
BEGIN
  SELECT * INTO v_from FROM public.accounts WHERE id = p_from_account;
  IF v_from.user_id != auth.uid() THEN RAISE EXCEPTION 'forbidden'; END IF;
  IF v_from.transfer_blocked THEN RAISE EXCEPTION 'transfers_blocked'; END IF;
  IF v_from.balance < p_amount THEN RAISE EXCEPTION 'insufficient_funds'; END IF;
  SELECT * INTO v_to FROM public.accounts WHERE account_number = p_to_account_number;
  IF v_to.id IS NULL THEN RAISE EXCEPTION 'recipient_not_found'; END IF;
  v_ref := 'IBK-' || to_char(now(), 'YYYYMMDDHH24MISS');
  INSERT INTO public.transactions (account_id, user_id, transaction_type, amount, description, reference_number, status, category, channel)
    VALUES (v_from.id, v_from.user_id, 'debit', p_amount, p_description, v_ref||'-D', 'completed', 'transfer', 'intrabank');
  INSERT INTO public.transactions (account_id, user_id, transaction_type, amount, description, reference_number, status, category, channel)
    VALUES (v_to.id, v_to.user_id, 'credit', p_amount, p_description, v_ref||'-C', 'completed', 'transfer', 'intrabank');
  RETURN jsonb_build_object('success', true, 'reference', v_ref);
END; $$;

CREATE OR REPLACE FUNCTION public.apply_domestic_transfer_charge(p_amount NUMERIC)
RETURNS NUMERIC LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT GREATEST(COALESCE(min_fee, 0), LEAST(COALESCE(max_fee, 999999), flat_fee + (p_amount * percentage_fee / 100)))
  FROM public.transfer_charges WHERE transfer_type = 'domestic' AND is_active = true LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.apply_international_transfer_charge(p_amount NUMERIC)
RETURNS NUMERIC LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT GREATEST(COALESCE(min_fee, 0), LEAST(COALESCE(max_fee, 999999), flat_fee + (p_amount * percentage_fee / 100)))
  FROM public.transfer_charges WHERE transfer_type = 'international' AND is_active = true LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.approve_external_transfer(p_id UUID)
RETURNS public.transfers LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_t public.transfers; v_ref TEXT;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  SELECT * INTO v_t FROM public.transfers WHERE id = p_id;
  v_ref := 'EXT-' || to_char(now(), 'YYYYMMDDHH24MISS');
  INSERT INTO public.transactions (account_id, user_id, transaction_type, amount, description, reference_number, status, category, channel)
    VALUES (v_t.from_account_id, v_t.user_id, 'debit', v_t.amount + v_t.fee, 'Transfer to '||v_t.recipient_name, v_ref, 'completed', 'transfer', 'external');
  UPDATE public.transfers SET status = 'approved', approved_by = auth.uid(), approved_at = now() WHERE id = p_id RETURNING * INTO v_t;
  RETURN v_t;
END; $$;

CREATE OR REPLACE FUNCTION public.approve_foreign_remittance(p_id UUID)
RETURNS public.foreign_remittances LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_t public.foreign_remittances; v_ref TEXT;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  SELECT * INTO v_t FROM public.foreign_remittances WHERE id = p_id;
  v_ref := 'INT-' || to_char(now(), 'YYYYMMDDHH24MISS');
  INSERT INTO public.transactions (account_id, user_id, transaction_type, amount, description, reference_number, status, category, channel)
    VALUES (v_t.from_account_id, v_t.user_id, 'debit', v_t.amount + v_t.fee, 'International transfer to '||v_t.recipient_name, v_ref, 'completed', 'transfer', 'international');
  UPDATE public.foreign_remittances SET status = 'approved', approved_by = auth.uid(), approved_at = now() WHERE id = p_id RETURNING * INTO v_t;
  RETURN v_t;
END; $$;

CREATE OR REPLACE FUNCTION public.get_account_transfer_limit(p_account_id UUID)
RETURNS NUMERIC LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT transfer_limit FROM public.accounts WHERE id = p_account_id;
$$;

CREATE OR REPLACE FUNCTION public.set_account_transfer_limit(p_account_id UUID, p_limit NUMERIC)
RETURNS public.accounts LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_row public.accounts;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  UPDATE public.accounts SET transfer_limit = p_limit WHERE id = p_account_id RETURNING * INTO v_row;
  RETURN v_row;
END; $$;

CREATE OR REPLACE FUNCTION public.reject_account_application(p_id UUID, p_reason TEXT)
RETURNS public.account_applications LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_row public.account_applications;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  UPDATE public.account_applications SET status = 'rejected', rejection_reason = p_reason, reviewed_by = auth.uid(), reviewed_at = now()
  WHERE id = p_id RETURNING * INTO v_row;
  RETURN v_row;
END; $$;

CREATE OR REPLACE FUNCTION public.admin_approve_deposit(p_type TEXT, p_id UUID, p_status TEXT, p_notes TEXT DEFAULT NULL)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_dep RECORD; v_ref TEXT;
BEGIN
  IF NOT has_role(auth.uid(), 'admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  IF p_type = 'crypto' THEN
    SELECT * INTO v_dep FROM public.crypto_deposits WHERE id = p_id;
    IF p_status = 'approved' AND v_dep.account_id IS NOT NULL THEN
      v_ref := 'CRY-' || to_char(now(), 'YYYYMMDDHH24MISS');
      INSERT INTO public.transactions (account_id, user_id, transaction_type, amount, description, reference_number, status, category, channel)
        VALUES (v_dep.account_id, v_dep.user_id, 'credit', v_dep.amount_usd, 'Crypto deposit ' || v_dep.crypto_type, v_ref, 'completed', 'deposit', 'crypto');
    END IF;
    UPDATE public.crypto_deposits SET status = p_status, rejection_reason = p_notes, approved_by = auth.uid(), approved_at = now() WHERE id = p_id;
  ELSIF p_type = 'check' THEN
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

-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('kyc-documents', 'kyc-documents', false) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('crypto-qr-codes', 'crypto-qr-codes', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('application-documents', 'application-documents', false) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('check-deposits', 'check-deposits', false) ON CONFLICT DO NOTHING;

CREATE POLICY "Avatar public read" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Avatar upload own" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Avatar update own" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Crypto QR public read" ON storage.objects FOR SELECT USING (bucket_id = 'crypto-qr-codes');
CREATE POLICY "Crypto QR admin write" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'crypto-qr-codes' AND has_role(auth.uid(), 'admin'));

CREATE POLICY "KYC owner read" ON storage.objects FOR SELECT USING (bucket_id = 'kyc-documents' AND (auth.uid()::text = (storage.foldername(name))[1] OR has_role(auth.uid(), 'admin')));
CREATE POLICY "KYC owner upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'kyc-documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "App docs public upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'application-documents');
CREATE POLICY "App docs admin read" ON storage.objects FOR SELECT USING (bucket_id = 'application-documents' AND has_role(auth.uid(), 'admin'));

CREATE POLICY "Check owner read" ON storage.objects FOR SELECT USING (bucket_id = 'check-deposits' AND (auth.uid()::text = (storage.foldername(name))[1] OR has_role(auth.uid(), 'admin')));
CREATE POLICY "Check owner upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'check-deposits' AND auth.uid()::text = (storage.foldername(name))[1]);
