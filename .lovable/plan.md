

## Wyseforte Bank — Full Backend Restoration

This is a comprehensive rebuild of the database, server-side env handling, edge function deployment, and email template system.

### 1. Fix `process.env` errors in client/server files

The three Supabase client files use `process.env` which fails in the Vite browser bundle. Fix:

- **`src/integrations/supabase/client.ts`** — remove `|| process.env.X` fallbacks; use only `import.meta.env.VITE_*`.
- **`src/integrations/supabase/client.server.ts`** — replace `process.env.X` with safe runtime access via `(globalThis as any).process?.env?.X` (works in edge runtimes that polyfill process; falls back to import.meta.env).
- **`src/integrations/supabase/auth-middleware.ts`** — same fix as `client.server.ts`.

Note: this is a Vite + React Router app (not TanStack Start despite scaffolded files). The server files exist but aren't actually used by the client — the fix prevents build/SSR crashes only.

### 2. Database schema migration (single comprehensive migration)

Create the following tables with RLS policies, triggers, and indexes:

| Table | Purpose |
|---|---|
| `accounts` | User bank accounts (checking, savings) with balances, account_number, status, transfer_limit, transfer_blocked |
| `transactions` | All transaction records (credit/debit), with reference_number, status, balance_after |
| `transfers` | External transfers (domestic + international) with approval workflow |
| `foreign_remittances` | International remittance with recipient details |
| `payees` | Saved transfer recipients |
| `bill_payments` | Utility bill payments |
| `account_statements` | Generated statements |
| `kyc_documents` | Identity documents with verification status |
| `loan_applications` | Loan requests with status |
| `loans` | Approved/disbursed loans |
| `loan_payments` | Repayment schedule entries |
| `loan_interest_rates` | Configurable rates per loan type |
| `transfer_charges` | Configurable fee structure |
| `support_tickets` | User support requests with admin responses |
| `account_applications` | Pre-signup application workflow with verification codes |
| `next_of_kin` | Per-user next-of-kin info |
| `notifications` | User-facing notifications |
| `user_security` | 2FA codes, security questions, lockout state |
| `website_settings` | Single-row bank/site config |
| `email_templates` | Editable email templates (template_name PK, subject_template, html_template, variables, is_active) |
| `crypto_deposits` + `crypto_deposit_config` | Crypto deposit workflow |
| `check_deposits` | Mobile check deposits |
| `admin_audit_logs` | Admin action history |

Plus an `avatars` storage bucket (public).

**RLS strategy:** users see only their own rows; admins (via `has_role`) see all. Admin-only tables fully gated.

### 3. RPC functions (SECURITY DEFINER where needed)

```text
get_email_templates()                 update_email_template(id,subject,body)
get_website_settings()                get_public_website_settings()
update_website_settings(...)
get_admin_notification_counts()       get_admin_users_paginated(...)
admin_approve_deposit(type,id,status,notes)
admin_create_transaction(...)         admin_update_transaction(...)
admin_delete_transaction(id)          admin_delete_account(id)
admin_clear_security_lock(user_id)    admin_disable_security_code(user_id)
admin_toggle_account_transfer_block(account_id)
admin_approve_loan_with_disbursement(loan_id)
admin_delete_loan(loan_id)
process_intrabank_transfer(...)       lookup_intrabank_recipient(account_no)
apply_domestic_transfer_charge(...)   apply_international_transfer_charge(...)
approve_external_transfer(id)         approve_foreign_remittance(id)
get_account_transfer_limit(id)        set_account_transfer_limit(id,limit)
reject_account_application(id,reason)
```

A trigger seeds a default checking account on profile creation. Another trigger maintains `account.balance` on transaction insert.

### 4. Email templates seeding (full set)

Seed `email_templates` with branded HTML for all 18 templates referenced in the admin UI:

```text
credit_alert, debit_alert,
account_application_verification, application_submitted,
application_approved, application_rejected,
crypto_deposit_pending, crypto_deposit_approved,
email_2fa_login, failed_login_alert,
password_reset, email_verification,
domestic_transfer_submitted, domestic_transfer_approved, domestic_transfer_rejected,
international_transfer_submitted, international_transfer_approved, international_transfer_rejected
```

Each row includes `subject_template`, `html_template` (styled, branded), `template_variables` (JSON array of placeholders like `{{full_name}}`, `{{amount}}`, `{{otp_code}}`), and `is_active = true`.

### 5. Deploy all edge functions

Deploy all 31 existing functions in `supabase/functions/` so RPCs and admin features work end-to-end:

```text
admin-create-user, admin-reset-password, admin-update-user-email,
approve-account-application, check-account-status, check-email-2fa,
check-email-availability, complete-password-reset, delete-user-completely,
process-account-application, process-kyc-documents, refresh-admin-stats,
resolve-login-identifier, send-application-decision, send-application-verification,
send-crypto-deposit-email, send-email-2fa, send-email-smtp, send-email-verification,
send-password-reset, send-support-notifications, send-transaction-email,
send-transfer-notification, setup-admin, test-smtp, track-failed-login,
track-login, verify-application-code, verify-email-2fa, verify-password-reset
```

Pre-existing `nodemailer` import error in `send-email-2fa` will be patched (switch to fetch-based SMTP via the shared `send-email-smtp` invocation pattern, or replace the `nodemailer` ESM import with the deno-compatible variant).

### 6. Notes / known limitations

- `src/integrations/supabase/types.ts` is auto-regenerated after the migration; existing components like `AdminAuditLogs` and `UsernameAvailabilityChecker` will resolve their TS errors automatically once the schema lands.
- `setup-admin.html` and `process-kyc-documents` rely on storage buckets — `kyc-documents` and `crypto-qr-codes` buckets will also be provisioned.
- The admin user `aitech2rule@proton.me` is preserved; the `handle_new_user` trigger backfills missing profile/role rows defensively (`ON CONFLICT DO NOTHING`).

### Order of execution

1. Patch `client.ts`, `client.server.ts`, `auth-middleware.ts`
2. Run the big migration (schema + RLS + triggers + RPCs + email_templates seed + buckets)
3. Patch `send-email-2fa` nodemailer import
4. Deploy all edge functions
5. Verify the homepage, admin login, and admin Email Templates tab render

