export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      account_applications: {
        Row: {
          account_type: string | null
          address: string | null
          annual_income: number | null
          city: string | null
          country: string | null
          created_at: string
          date_of_birth: string | null
          email: string
          email_verified: boolean
          employer: string | null
          first_name: string | null
          full_name: string
          gender: string | null
          id: string
          id_document_url: string | null
          id_expiry_date: string | null
          id_issuing_country: string | null
          id_number: string | null
          id_type: string | null
          initial_deposit: number | null
          is_pep: boolean | null
          last_name: string | null
          marital_status: string | null
          marketing_consent: boolean | null
          metadata: Json | null
          middle_name: string | null
          nationality: string | null
          occupation: string | null
          password_hash: string | null
          phone: string | null
          postal_code: string | null
          preferred_currency: string | null
          proof_of_address_url: string | null
          purpose_of_account: string | null
          reference_number: string | null
          rejection_reason: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          selfie_url: string | null
          source_of_funds: string | null
          ssn_last_four: string | null
          state: string | null
          status: string
          terms_accepted: boolean | null
          title: string | null
          updated_at: string
          username: string | null
          verification_code: string | null
          verification_code_expires_at: string | null
        }
        Insert: {
          account_type?: string | null
          address?: string | null
          annual_income?: number | null
          city?: string | null
          country?: string | null
          created_at?: string
          date_of_birth?: string | null
          email: string
          email_verified?: boolean
          employer?: string | null
          first_name?: string | null
          full_name: string
          gender?: string | null
          id?: string
          id_document_url?: string | null
          id_expiry_date?: string | null
          id_issuing_country?: string | null
          id_number?: string | null
          id_type?: string | null
          initial_deposit?: number | null
          is_pep?: boolean | null
          last_name?: string | null
          marital_status?: string | null
          marketing_consent?: boolean | null
          metadata?: Json | null
          middle_name?: string | null
          nationality?: string | null
          occupation?: string | null
          password_hash?: string | null
          phone?: string | null
          postal_code?: string | null
          preferred_currency?: string | null
          proof_of_address_url?: string | null
          purpose_of_account?: string | null
          reference_number?: string | null
          rejection_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          selfie_url?: string | null
          source_of_funds?: string | null
          ssn_last_four?: string | null
          state?: string | null
          status?: string
          terms_accepted?: boolean | null
          title?: string | null
          updated_at?: string
          username?: string | null
          verification_code?: string | null
          verification_code_expires_at?: string | null
        }
        Update: {
          account_type?: string | null
          address?: string | null
          annual_income?: number | null
          city?: string | null
          country?: string | null
          created_at?: string
          date_of_birth?: string | null
          email?: string
          email_verified?: boolean
          employer?: string | null
          first_name?: string | null
          full_name?: string
          gender?: string | null
          id?: string
          id_document_url?: string | null
          id_expiry_date?: string | null
          id_issuing_country?: string | null
          id_number?: string | null
          id_type?: string | null
          initial_deposit?: number | null
          is_pep?: boolean | null
          last_name?: string | null
          marital_status?: string | null
          marketing_consent?: boolean | null
          metadata?: Json | null
          middle_name?: string | null
          nationality?: string | null
          occupation?: string | null
          password_hash?: string | null
          phone?: string | null
          postal_code?: string | null
          preferred_currency?: string | null
          proof_of_address_url?: string | null
          purpose_of_account?: string | null
          reference_number?: string | null
          rejection_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          selfie_url?: string | null
          source_of_funds?: string | null
          ssn_last_four?: string | null
          state?: string | null
          status?: string
          terms_accepted?: boolean | null
          title?: string | null
          updated_at?: string
          username?: string | null
          verification_code?: string | null
          verification_code_expires_at?: string | null
        }
        Relationships: []
      }
      account_statements: {
        Row: {
          account_id: string
          closing_balance: number | null
          created_at: string
          file_url: string | null
          id: string
          opening_balance: number | null
          statement_period_end: string
          statement_period_start: string
          statement_type: string
          total_credits: number | null
          total_debits: number | null
          transaction_count: number | null
          user_id: string
        }
        Insert: {
          account_id: string
          closing_balance?: number | null
          created_at?: string
          file_url?: string | null
          id?: string
          opening_balance?: number | null
          statement_period_end: string
          statement_period_start: string
          statement_type?: string
          total_credits?: number | null
          total_debits?: number | null
          transaction_count?: number | null
          user_id: string
        }
        Update: {
          account_id?: string
          closing_balance?: number | null
          created_at?: string
          file_url?: string | null
          id?: string
          opening_balance?: number | null
          statement_period_end?: string
          statement_period_start?: string
          statement_type?: string
          total_credits?: number | null
          total_debits?: number | null
          transaction_count?: number | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "account_statements_account_id_fkey"
            columns: ["account_id"]
            isOneToOne: false
            referencedRelation: "accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      accounts: {
        Row: {
          account_number: string
          account_type: string
          available_balance: number
          balance: number
          created_at: string
          currency: string
          iban: string | null
          id: string
          routing_number: string | null
          status: string
          swift_code: string | null
          transfer_blocked: boolean
          transfer_limit: number
          updated_at: string
          user_id: string
        }
        Insert: {
          account_number: string
          account_type?: string
          available_balance?: number
          balance?: number
          created_at?: string
          currency?: string
          iban?: string | null
          id?: string
          routing_number?: string | null
          status?: string
          swift_code?: string | null
          transfer_blocked?: boolean
          transfer_limit?: number
          updated_at?: string
          user_id: string
        }
        Update: {
          account_number?: string
          account_type?: string
          available_balance?: number
          balance?: number
          created_at?: string
          currency?: string
          iban?: string | null
          id?: string
          routing_number?: string | null
          status?: string
          swift_code?: string | null
          transfer_blocked?: boolean
          transfer_limit?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "accounts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_audit_logs: {
        Row: {
          action: string
          admin_id: string
          created_at: string
          entity_id: string | null
          entity_type: string | null
          id: string
          ip_address: string | null
          new_values: Json | null
          old_values: Json | null
          user_agent: string | null
        }
        Insert: {
          action: string
          admin_id: string
          created_at?: string
          entity_id?: string | null
          entity_type?: string | null
          id?: string
          ip_address?: string | null
          new_values?: Json | null
          old_values?: Json | null
          user_agent?: string | null
        }
        Update: {
          action?: string
          admin_id?: string
          created_at?: string
          entity_id?: string | null
          entity_type?: string | null
          id?: string
          ip_address?: string | null
          new_values?: Json | null
          old_values?: Json | null
          user_agent?: string | null
        }
        Relationships: []
      }
      bill_payments: {
        Row: {
          account_id: string
          amount: number
          biller_account: string | null
          biller_name: string
          category: string | null
          created_at: string
          id: string
          reference_number: string
          scheduled_date: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          account_id: string
          amount: number
          biller_account?: string | null
          biller_name: string
          category?: string | null
          created_at?: string
          id?: string
          reference_number: string
          scheduled_date?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          account_id?: string
          amount?: number
          biller_account?: string | null
          biller_name?: string
          category?: string | null
          created_at?: string
          id?: string
          reference_number?: string
          scheduled_date?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "bill_payments_account_id_fkey"
            columns: ["account_id"]
            isOneToOne: false
            referencedRelation: "accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      check_deposits: {
        Row: {
          account_id: string
          amount: number
          approved_at: string | null
          approved_by: string | null
          back_image_url: string | null
          check_number: string | null
          created_at: string
          front_image_url: string | null
          id: string
          rejection_reason: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          account_id: string
          amount: number
          approved_at?: string | null
          approved_by?: string | null
          back_image_url?: string | null
          check_number?: string | null
          created_at?: string
          front_image_url?: string | null
          id?: string
          rejection_reason?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          account_id?: string
          amount?: number
          approved_at?: string | null
          approved_by?: string | null
          back_image_url?: string | null
          check_number?: string | null
          created_at?: string
          front_image_url?: string | null
          id?: string
          rejection_reason?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "check_deposits_account_id_fkey"
            columns: ["account_id"]
            isOneToOne: false
            referencedRelation: "accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      crypto_deposit_config: {
        Row: {
          created_at: string
          crypto_type: string
          id: string
          is_enabled: boolean
          min_deposit: number | null
          network: string | null
          qr_code_url: string | null
          updated_at: string
          wallet_address: string
        }
        Insert: {
          created_at?: string
          crypto_type: string
          id?: string
          is_enabled?: boolean
          min_deposit?: number | null
          network?: string | null
          qr_code_url?: string | null
          updated_at?: string
          wallet_address: string
        }
        Update: {
          created_at?: string
          crypto_type?: string
          id?: string
          is_enabled?: boolean
          min_deposit?: number | null
          network?: string | null
          qr_code_url?: string | null
          updated_at?: string
          wallet_address?: string
        }
        Relationships: []
      }
      crypto_deposits: {
        Row: {
          account_id: string | null
          amount_crypto: number
          amount_usd: number
          approved_at: string | null
          approved_by: string | null
          created_at: string
          crypto_type: string
          id: string
          proof_url: string | null
          rejection_reason: string | null
          status: string
          transaction_hash: string | null
          updated_at: string
          user_id: string
          wallet_address: string | null
        }
        Insert: {
          account_id?: string | null
          amount_crypto: number
          amount_usd: number
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          crypto_type: string
          id?: string
          proof_url?: string | null
          rejection_reason?: string | null
          status?: string
          transaction_hash?: string | null
          updated_at?: string
          user_id: string
          wallet_address?: string | null
        }
        Update: {
          account_id?: string | null
          amount_crypto?: number
          amount_usd?: number
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          crypto_type?: string
          id?: string
          proof_url?: string | null
          rejection_reason?: string | null
          status?: string
          transaction_hash?: string | null
          updated_at?: string
          user_id?: string
          wallet_address?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "crypto_deposits_account_id_fkey"
            columns: ["account_id"]
            isOneToOne: false
            referencedRelation: "accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      email_templates: {
        Row: {
          created_at: string
          html_template: string
          id: string
          is_active: boolean
          subject_template: string
          template_name: string
          template_variables: Json | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          html_template: string
          id?: string
          is_active?: boolean
          subject_template: string
          template_name: string
          template_variables?: Json | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          html_template?: string
          id?: string
          is_active?: boolean
          subject_template?: string
          template_name?: string
          template_variables?: Json | null
          updated_at?: string
        }
        Relationships: []
      }
      foreign_remittances: {
        Row: {
          account_id: string | null
          amount: number
          approved_at: string | null
          approved_by: string | null
          bank_name: string | null
          created_at: string
          currency: string
          exchange_rate: number | null
          fee: number
          from_account_id: string | null
          iban: string | null
          id: string
          purpose: string | null
          recipient_account: string | null
          recipient_account_number: string
          recipient_address: string | null
          recipient_bank_address: string | null
          recipient_bank_name: string
          recipient_country: string
          recipient_currency: string
          recipient_name: string
          reference_number: string
          rejection_reason: string | null
          status: string
          swift_code: string
          updated_at: string
          user_id: string
        }
        Insert: {
          account_id?: string | null
          amount: number
          approved_at?: string | null
          approved_by?: string | null
          bank_name?: string | null
          created_at?: string
          currency?: string
          exchange_rate?: number | null
          fee?: number
          from_account_id?: string | null
          iban?: string | null
          id?: string
          purpose?: string | null
          recipient_account?: string | null
          recipient_account_number: string
          recipient_address?: string | null
          recipient_bank_address?: string | null
          recipient_bank_name: string
          recipient_country: string
          recipient_currency?: string
          recipient_name: string
          reference_number: string
          rejection_reason?: string | null
          status?: string
          swift_code: string
          updated_at?: string
          user_id: string
        }
        Update: {
          account_id?: string | null
          amount?: number
          approved_at?: string | null
          approved_by?: string | null
          bank_name?: string | null
          created_at?: string
          currency?: string
          exchange_rate?: number | null
          fee?: number
          from_account_id?: string | null
          iban?: string | null
          id?: string
          purpose?: string | null
          recipient_account?: string | null
          recipient_account_number?: string
          recipient_address?: string | null
          recipient_bank_address?: string | null
          recipient_bank_name?: string
          recipient_country?: string
          recipient_currency?: string
          recipient_name?: string
          reference_number?: string
          rejection_reason?: string | null
          status?: string
          swift_code?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "foreign_remittances_from_account_id_fkey"
            columns: ["from_account_id"]
            isOneToOne: false
            referencedRelation: "accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      kyc_documents: {
        Row: {
          document_number: string | null
          document_type: string
          file_name: string | null
          file_url: string
          id: string
          metadata: Json | null
          rejection_reason: string | null
          review_notes: string | null
          reviewed_at: string | null
          uploaded_at: string
          user_id: string
          verification_status: string
          verified_at: string | null
          verified_by: string | null
        }
        Insert: {
          document_number?: string | null
          document_type: string
          file_name?: string | null
          file_url: string
          id?: string
          metadata?: Json | null
          rejection_reason?: string | null
          review_notes?: string | null
          reviewed_at?: string | null
          uploaded_at?: string
          user_id: string
          verification_status?: string
          verified_at?: string | null
          verified_by?: string | null
        }
        Update: {
          document_number?: string | null
          document_type?: string
          file_name?: string | null
          file_url?: string
          id?: string
          metadata?: Json | null
          rejection_reason?: string | null
          review_notes?: string | null
          reviewed_at?: string | null
          uploaded_at?: string
          user_id?: string
          verification_status?: string
          verified_at?: string | null
          verified_by?: string | null
        }
        Relationships: []
      }
      loan_applications: {
        Row: {
          created_at: string
          employer_name: string | null
          employment_status: string | null
          id: string
          loan_type: string
          monthly_income: number | null
          purpose: string | null
          rejection_reason: string | null
          requested_amount: number
          reviewed_at: string | null
          reviewed_by: string | null
          status: string
          term_months: number
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          employer_name?: string | null
          employment_status?: string | null
          id?: string
          loan_type: string
          monthly_income?: number | null
          purpose?: string | null
          rejection_reason?: string | null
          requested_amount: number
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          term_months: number
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          employer_name?: string | null
          employment_status?: string | null
          id?: string
          loan_type?: string
          monthly_income?: number | null
          purpose?: string | null
          rejection_reason?: string | null
          requested_amount?: number
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string
          term_months?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      loan_interest_rates: {
        Row: {
          created_at: string
          id: string
          interest_rate: number
          is_active: boolean
          loan_type: string
          max_amount: number | null
          max_term_months: number | null
          min_amount: number | null
          min_term_months: number | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          interest_rate: number
          is_active?: boolean
          loan_type: string
          max_amount?: number | null
          max_term_months?: number | null
          min_amount?: number | null
          min_term_months?: number | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          interest_rate?: number
          is_active?: boolean
          loan_type?: string
          max_amount?: number | null
          max_term_months?: number | null
          min_amount?: number | null
          min_term_months?: number | null
          updated_at?: string
        }
        Relationships: []
      }
      loan_payments: {
        Row: {
          amount: number
          created_at: string
          id: string
          interest_portion: number | null
          loan_id: string
          payment_date: string
          principal_portion: number | null
          status: string
          user_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          interest_portion?: number | null
          loan_id: string
          payment_date: string
          principal_portion?: number | null
          status?: string
          user_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          interest_portion?: number | null
          loan_id?: string
          payment_date?: string
          principal_portion?: number | null
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "loan_payments_loan_id_fkey"
            columns: ["loan_id"]
            isOneToOne: false
            referencedRelation: "loans"
            referencedColumns: ["id"]
          },
        ]
      }
      loans: {
        Row: {
          account_id: string | null
          application_id: string | null
          created_at: string
          disbursed_at: string | null
          id: string
          interest_rate: number
          loan_amount: number | null
          loan_type: string
          monthly_payment: number | null
          next_payment_date: string | null
          outstanding_balance: number
          principal_amount: number
          remaining_balance: number | null
          status: string
          term_months: number
          updated_at: string
          user_id: string
        }
        Insert: {
          account_id?: string | null
          application_id?: string | null
          created_at?: string
          disbursed_at?: string | null
          id?: string
          interest_rate: number
          loan_amount?: number | null
          loan_type: string
          monthly_payment?: number | null
          next_payment_date?: string | null
          outstanding_balance: number
          principal_amount: number
          remaining_balance?: number | null
          status?: string
          term_months: number
          updated_at?: string
          user_id: string
        }
        Update: {
          account_id?: string | null
          application_id?: string | null
          created_at?: string
          disbursed_at?: string | null
          id?: string
          interest_rate?: number
          loan_amount?: number | null
          loan_type?: string
          monthly_payment?: number | null
          next_payment_date?: string | null
          outstanding_balance?: number
          principal_amount?: number
          remaining_balance?: number | null
          status?: string
          term_months?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "loans_account_id_fkey"
            columns: ["account_id"]
            isOneToOne: false
            referencedRelation: "accounts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "loans_application_id_fkey"
            columns: ["application_id"]
            isOneToOne: false
            referencedRelation: "loan_applications"
            referencedColumns: ["id"]
          },
        ]
      }
      next_of_kin: {
        Row: {
          address: string | null
          created_at: string
          email: string | null
          full_name: string
          id: string
          phone: string | null
          relationship: string
          updated_at: string
          user_id: string
        }
        Insert: {
          address?: string | null
          created_at?: string
          email?: string | null
          full_name: string
          id?: string
          phone?: string | null
          relationship: string
          updated_at?: string
          user_id: string
        }
        Update: {
          address?: string | null
          created_at?: string
          email?: string | null
          full_name?: string
          id?: string
          phone?: string | null
          relationship?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      notifications: {
        Row: {
          created_at: string
          id: string
          is_read: boolean
          link: string | null
          message: string
          metadata: Json | null
          notification_type: string | null
          title: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_read?: boolean
          link?: string | null
          message: string
          metadata?: Json | null
          notification_type?: string | null
          title: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          is_read?: boolean
          link?: string | null
          message?: string
          metadata?: Json | null
          notification_type?: string | null
          title?: string
          user_id?: string
        }
        Relationships: []
      }
      payees: {
        Row: {
          account_number: string
          bank_name: string | null
          country: string | null
          created_at: string
          id: string
          name: string
          nickname: string | null
          payee_type: string | null
          routing_number: string | null
          swift_code: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          account_number: string
          bank_name?: string | null
          country?: string | null
          created_at?: string
          id?: string
          name: string
          nickname?: string | null
          payee_type?: string | null
          routing_number?: string | null
          swift_code?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          account_number?: string
          bank_name?: string | null
          country?: string | null
          created_at?: string
          id?: string
          name?: string
          nickname?: string | null
          payee_type?: string | null
          routing_number?: string | null
          swift_code?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          account_locked: boolean
          address: string | null
          avatar_url: string | null
          created_at: string
          date_of_birth: string | null
          email: string
          full_name: string | null
          id: string
          loan_applications_allowed: boolean
          phone: string | null
          title: string | null
          transfer_code_1_enabled: boolean
          transfer_code_2_enabled: boolean
          transfer_code_3_enabled: boolean
          updated_at: string
          username: string | null
        }
        Insert: {
          account_locked?: boolean
          address?: string | null
          avatar_url?: string | null
          created_at?: string
          date_of_birth?: string | null
          email: string
          full_name?: string | null
          id: string
          loan_applications_allowed?: boolean
          phone?: string | null
          title?: string | null
          transfer_code_1_enabled?: boolean
          transfer_code_2_enabled?: boolean
          transfer_code_3_enabled?: boolean
          updated_at?: string
          username?: string | null
        }
        Update: {
          account_locked?: boolean
          address?: string | null
          avatar_url?: string | null
          created_at?: string
          date_of_birth?: string | null
          email?: string
          full_name?: string | null
          id?: string
          loan_applications_allowed?: boolean
          phone?: string | null
          title?: string | null
          transfer_code_1_enabled?: boolean
          transfer_code_2_enabled?: boolean
          transfer_code_3_enabled?: boolean
          updated_at?: string
          username?: string | null
        }
        Relationships: []
      }
      support_tickets: {
        Row: {
          admin_response: string | null
          category: string | null
          created_at: string
          id: string
          message: string
          priority: string | null
          responded_at: string | null
          responded_by: string | null
          status: string
          subject: string
          ticket_number: string
          updated_at: string
          user_id: string
        }
        Insert: {
          admin_response?: string | null
          category?: string | null
          created_at?: string
          id?: string
          message: string
          priority?: string | null
          responded_at?: string | null
          responded_by?: string | null
          status?: string
          subject: string
          ticket_number: string
          updated_at?: string
          user_id: string
        }
        Update: {
          admin_response?: string | null
          category?: string | null
          created_at?: string
          id?: string
          message?: string
          priority?: string | null
          responded_at?: string | null
          responded_by?: string | null
          status?: string
          subject?: string
          ticket_number?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      transactions: {
        Row: {
          account_id: string
          amount: number
          balance_after: number | null
          bank_name: string | null
          category: string | null
          channel: string | null
          created_at: string
          description: string | null
          id: string
          metadata: Json | null
          recipient_account: string | null
          recipient_name: string | null
          reference_number: string
          routing_code: string | null
          status: string
          transaction_type: string
          updated_at: string
          user_id: string
        }
        Insert: {
          account_id: string
          amount: number
          balance_after?: number | null
          bank_name?: string | null
          category?: string | null
          channel?: string | null
          created_at?: string
          description?: string | null
          id?: string
          metadata?: Json | null
          recipient_account?: string | null
          recipient_name?: string | null
          reference_number: string
          routing_code?: string | null
          status?: string
          transaction_type: string
          updated_at?: string
          user_id: string
        }
        Update: {
          account_id?: string
          amount?: number
          balance_after?: number | null
          bank_name?: string | null
          category?: string | null
          channel?: string | null
          created_at?: string
          description?: string | null
          id?: string
          metadata?: Json | null
          recipient_account?: string | null
          recipient_name?: string | null
          reference_number?: string
          routing_code?: string | null
          status?: string
          transaction_type?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "transactions_account_id_fkey"
            columns: ["account_id"]
            isOneToOne: false
            referencedRelation: "accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      transfer_charges: {
        Row: {
          created_at: string
          flat_fee: number
          id: string
          is_active: boolean
          max_fee: number | null
          min_fee: number | null
          percentage_fee: number
          transfer_type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          flat_fee?: number
          id?: string
          is_active?: boolean
          max_fee?: number | null
          min_fee?: number | null
          percentage_fee?: number
          transfer_type: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          flat_fee?: number
          id?: string
          is_active?: boolean
          max_fee?: number | null
          min_fee?: number | null
          percentage_fee?: number
          transfer_type?: string
          updated_at?: string
        }
        Relationships: []
      }
      transfers: {
        Row: {
          amount: number
          approved_at: string | null
          approved_by: string | null
          created_at: string
          currency: string
          description: string | null
          fee: number
          from_account_id: string | null
          id: string
          recipient_account_number: string
          recipient_bank: string | null
          recipient_name: string
          recipient_routing: string | null
          reference_number: string
          rejection_reason: string | null
          status: string
          transfer_type: string
          updated_at: string
          user_id: string
        }
        Insert: {
          amount: number
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          currency?: string
          description?: string | null
          fee?: number
          from_account_id?: string | null
          id?: string
          recipient_account_number: string
          recipient_bank?: string | null
          recipient_name: string
          recipient_routing?: string | null
          reference_number: string
          rejection_reason?: string | null
          status?: string
          transfer_type?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          amount?: number
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          currency?: string
          description?: string | null
          fee?: number
          from_account_id?: string | null
          id?: string
          recipient_account_number?: string
          recipient_bank?: string | null
          recipient_name?: string
          recipient_routing?: string | null
          reference_number?: string
          rejection_reason?: string | null
          status?: string
          transfer_type?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "transfers_from_account_id_fkey"
            columns: ["from_account_id"]
            isOneToOne: false
            referencedRelation: "accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          created_at: string
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
      user_security: {
        Row: {
          created_at: string
          email_2fa_enabled: boolean
          failed_login_attempts: number
          id: string
          last_login_at: string | null
          last_login_ip: string | null
          locked_until: string | null
          security_answer_hash: string | null
          security_code: string | null
          security_code_enabled: boolean
          security_question: string | null
          two_fa_enabled: boolean
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          email_2fa_enabled?: boolean
          failed_login_attempts?: number
          id?: string
          last_login_at?: string | null
          last_login_ip?: string | null
          locked_until?: string | null
          security_answer_hash?: string | null
          security_code?: string | null
          security_code_enabled?: boolean
          security_question?: string | null
          two_fa_enabled?: boolean
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          email_2fa_enabled?: boolean
          failed_login_attempts?: number
          id?: string
          last_login_at?: string | null
          last_login_ip?: string | null
          locked_until?: string | null
          security_answer_hash?: string | null
          security_code?: string | null
          security_code_enabled?: boolean
          security_question?: string | null
          two_fa_enabled?: boolean
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      website_settings: {
        Row: {
          bank_address: string | null
          bank_email: string | null
          bank_name: string
          bank_phone: string | null
          bank_short_name: string | null
          contact_email: string | null
          created_at: string
          favicon_url: string | null
          id: string
          logo_url: string | null
          maintenance_mode: boolean
          metadata: Json | null
          primary_color: string | null
          secondary_color: string | null
          smtp_from_email: string | null
          smtp_from_name: string | null
          smtp_host: string | null
          smtp_password: string | null
          smtp_port: number | null
          smtp_user: string | null
          social_facebook: string | null
          social_instagram: string | null
          social_linkedin: string | null
          social_twitter: string | null
          super_admin_email: string | null
          updated_at: string
        }
        Insert: {
          bank_address?: string | null
          bank_email?: string | null
          bank_name?: string
          bank_phone?: string | null
          bank_short_name?: string | null
          contact_email?: string | null
          created_at?: string
          favicon_url?: string | null
          id?: string
          logo_url?: string | null
          maintenance_mode?: boolean
          metadata?: Json | null
          primary_color?: string | null
          secondary_color?: string | null
          smtp_from_email?: string | null
          smtp_from_name?: string | null
          smtp_host?: string | null
          smtp_password?: string | null
          smtp_port?: number | null
          smtp_user?: string | null
          social_facebook?: string | null
          social_instagram?: string | null
          social_linkedin?: string | null
          social_twitter?: string | null
          super_admin_email?: string | null
          updated_at?: string
        }
        Update: {
          bank_address?: string | null
          bank_email?: string | null
          bank_name?: string
          bank_phone?: string | null
          bank_short_name?: string | null
          contact_email?: string | null
          created_at?: string
          favicon_url?: string | null
          id?: string
          logo_url?: string | null
          maintenance_mode?: boolean
          metadata?: Json | null
          primary_color?: string | null
          secondary_color?: string | null
          smtp_from_email?: string | null
          smtp_from_name?: string | null
          smtp_host?: string | null
          smtp_password?: string | null
          smtp_port?: number | null
          smtp_user?: string | null
          social_facebook?: string | null
          social_instagram?: string | null
          social_linkedin?: string | null
          social_twitter?: string | null
          super_admin_email?: string | null
          updated_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      admin_check_deposits_view: {
        Row: {
          account_id: string | null
          account_number: string | null
          amount: number | null
          approved_at: string | null
          approved_by: string | null
          back_image_url: string | null
          check_number: string | null
          created_at: string | null
          email: string | null
          front_image_url: string | null
          full_name: string | null
          id: string | null
          rejection_reason: string | null
          status: string | null
          updated_at: string | null
          user_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "check_deposits_account_id_fkey"
            columns: ["account_id"]
            isOneToOne: false
            referencedRelation: "accounts"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_crypto_deposits_view: {
        Row: {
          account_id: string | null
          account_number: string | null
          amount_crypto: number | null
          amount_usd: number | null
          approved_at: string | null
          approved_by: string | null
          created_at: string | null
          crypto_type: string | null
          email: string | null
          full_name: string | null
          id: string | null
          proof_url: string | null
          rejection_reason: string | null
          status: string | null
          transaction_hash: string | null
          updated_at: string | null
          user_id: string | null
          wallet_address: string | null
        }
        Relationships: [
          {
            foreignKeyName: "crypto_deposits_account_id_fkey"
            columns: ["account_id"]
            isOneToOne: false
            referencedRelation: "accounts"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      admin_approve_deposit: {
        Args: {
          deposit_id: string
          deposit_type: string
          p_notes?: string
          p_status: string
        }
        Returns: Json
      }
      admin_approve_loan_with_disbursement: {
        Args: { p_loan_id: string }
        Returns: {
          account_id: string | null
          application_id: string | null
          created_at: string
          disbursed_at: string | null
          id: string
          interest_rate: number
          loan_amount: number | null
          loan_type: string
          monthly_payment: number | null
          next_payment_date: string | null
          outstanding_balance: number
          principal_amount: number
          remaining_balance: number | null
          status: string
          term_months: number
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "loans"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_clear_security_lock: {
        Args: { p_user_id: string }
        Returns: boolean
      }
      admin_create_transaction: {
        Args: {
          p_account_id: string
          p_amount: number
          p_category?: string
          p_description: string
          p_type: string
        }
        Returns: {
          account_id: string
          amount: number
          balance_after: number | null
          bank_name: string | null
          category: string | null
          channel: string | null
          created_at: string
          description: string | null
          id: string
          metadata: Json | null
          recipient_account: string | null
          recipient_name: string | null
          reference_number: string
          routing_code: string | null
          status: string
          transaction_type: string
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "transactions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_delete_account: { Args: { p_id: string }; Returns: boolean }
      admin_delete_loan: { Args: { p_loan_id: string }; Returns: boolean }
      admin_delete_transaction: {
        Args: { transaction_id: string }
        Returns: boolean
      }
      admin_disable_security_code: {
        Args: { p_user_id: string }
        Returns: boolean
      }
      admin_toggle_account_transfer_block: {
        Args: { p_account_id: string }
        Returns: {
          account_number: string
          account_type: string
          available_balance: number
          balance: number
          created_at: string
          currency: string
          iban: string | null
          id: string
          routing_number: string | null
          status: string
          swift_code: string | null
          transfer_blocked: boolean
          transfer_limit: number
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "accounts"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_update_transaction: {
        Args: {
          p_amount?: number
          p_description?: string
          p_status?: string
          transaction_id: string
        }
        Returns: Json
      }
      apply_domestic_transfer_charge: {
        Args: { p_account_id: string; p_amount: number }
        Returns: number
      }
      apply_international_transfer_charge: {
        Args: { p_account_id: string; p_amount: number }
        Returns: number
      }
      approve_external_transfer: {
        Args: { p_reference_number?: string; p_transaction_id: string }
        Returns: Json
      }
      approve_foreign_remittance: {
        Args: { p_reference_number?: string; remittance_id: string }
        Returns: Json
      }
      generate_account_number: {
        Args: { account_type: string }
        Returns: string
      }
      get_account_transfer_limit: {
        Args: { p_account_id: string }
        Returns: number
      }
      get_admin_notification_counts: { Args: never; Returns: Json }
      get_admin_users_paginated: {
        Args: { p_limit?: number; p_search?: string; page_number?: number }
        Returns: {
          account_count: number
          account_locked: boolean
          created_at: string
          email: string
          full_name: string
          id: string
          phone: string
          total_balance: number
          total_count: number
          username: string
        }[]
      }
      get_email_templates: {
        Args: never
        Returns: {
          created_at: string
          html_template: string
          id: string
          is_active: boolean
          subject_template: string
          template_name: string
          template_variables: Json | null
          updated_at: string
        }[]
        SetofOptions: {
          from: "*"
          to: "email_templates"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      get_public_website_settings: {
        Args: never
        Returns: {
          bank_address: string
          bank_name: string
          bank_phone: string
          bank_short_name: string
          contact_email: string
          favicon_url: string
          logo_url: string
          primary_color: string
          secondary_color: string
          social_facebook: string
          social_instagram: string
          social_linkedin: string
          social_twitter: string
        }[]
      }
      get_website_settings: {
        Args: never
        Returns: {
          bank_address: string | null
          bank_email: string | null
          bank_name: string
          bank_phone: string | null
          bank_short_name: string | null
          contact_email: string | null
          created_at: string
          favicon_url: string | null
          id: string
          logo_url: string | null
          maintenance_mode: boolean
          metadata: Json | null
          primary_color: string | null
          secondary_color: string | null
          smtp_from_email: string | null
          smtp_from_name: string | null
          smtp_host: string | null
          smtp_password: string | null
          smtp_port: number | null
          smtp_user: string | null
          social_facebook: string | null
          social_instagram: string | null
          social_linkedin: string | null
          social_twitter: string | null
          super_admin_email: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "website_settings"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      lookup_intrabank_recipient: {
        Args: { p_account_number: string }
        Returns: {
          account_id: string
          account_number: string
          full_name: string
          user_id: string
        }[]
      }
      process_intrabank_transfer: {
        Args: {
          p_amount: number
          p_description: string
          p_from_account: string
          p_to_account_number: string
        }
        Returns: Json
      }
      reject_account_application: {
        Args: { p_application_id: string; p_reason: string }
        Returns: Json
      }
      set_account_transfer_limit: {
        Args: { p_account_id: string; p_daily_limit: number }
        Returns: Json
      }
      update_email_template: {
        Args: {
          p_html: string
          p_is_active?: boolean
          p_subject: string
          template_id: string
        }
        Returns: Json
      }
      update_website_settings: {
        Args: { p_settings: Json }
        Returns: {
          bank_address: string | null
          bank_email: string | null
          bank_name: string
          bank_phone: string | null
          bank_short_name: string | null
          contact_email: string | null
          created_at: string
          favicon_url: string | null
          id: string
          logo_url: string | null
          maintenance_mode: boolean
          metadata: Json | null
          primary_color: string | null
          secondary_color: string | null
          smtp_from_email: string | null
          smtp_from_name: string | null
          smtp_host: string | null
          smtp_password: string | null
          smtp_port: number | null
          smtp_user: string | null
          social_facebook: string | null
          social_instagram: string | null
          social_linkedin: string | null
          social_twitter: string | null
          super_admin_email: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "website_settings"
          isOneToOne: true
          isSetofReturn: false
        }
      }
    }
    Enums: {
      app_role: "admin" | "user"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["admin", "user"],
    },
  },
} as const
