-- =============================================
-- Supabase Auth Schema Setup
-- =============================================
-- Extended auth schema setup for Supabase authentication

\echo 'Setting up extended auth schema...'

-- Create auth schema if not exists (should already exist from 01-initial-schema.sql)
CREATE SCHEMA IF NOT EXISTS auth;

-- Add additional auth tables
CREATE TABLE IF NOT EXISTS auth.refresh_tokens (
    instance_id UUID,
    id BIGSERIAL PRIMARY KEY,
    token VARCHAR(255) UNIQUE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    parent VARCHAR(255),
    session_id UUID
);

CREATE TABLE IF NOT EXISTS auth.instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    uuid UUID,
    raw_base_config TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS auth.schema_migrations (
    version VARCHAR(255) PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS auth.audit_log_entries (
    instance_id UUID,
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payload JSON,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address VARCHAR(64) NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS auth.flow_state (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    auth_code TEXT NOT NULL,
    code_challenge_method text NOT NULL,
    code_challenge TEXT NOT NULL,
    provider_type TEXT NOT NULL,
    provider_access_token TEXT,
    provider_refresh_token TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    authentication_method TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS auth.identities (
    provider_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    identity_data JSONB NOT NULL,
    provider TEXT NOT NULL,
    last_sign_in_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    email TEXT GENERATED ALWAYS AS (identity_data->>'email') STORED,
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
);

CREATE TABLE IF NOT EXISTS auth.sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    factor_id UUID,
    aal auth.aal_level,
    not_after TIMESTAMPTZ,
    refreshed_at TIMESTAMP,
    user_agent TEXT,
    ip INET,
    tag TEXT
);

-- Create enum types for auth
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'aal_level') THEN
        CREATE TYPE auth.aal_level AS ENUM ('aal1', 'aal2', 'aal3');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'factor_type') THEN
        CREATE TYPE auth.factor_type AS ENUM ('totp', 'webauthn');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'factor_status') THEN
        CREATE TYPE auth.factor_status AS ENUM ('unverified', 'verified');
    END IF;
END $$;

-- MFA tables
CREATE TABLE IF NOT EXISTS auth.mfa_amr_claims (
    session_id UUID NOT NULL REFERENCES auth.sessions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    authentication_method TEXT NOT NULL,
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
);

CREATE TABLE IF NOT EXISTS auth.mfa_factors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    friendly_name TEXT,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    secret TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS auth.mfa_challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    factor_id UUID NOT NULL REFERENCES auth.mfa_factors(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    verified_at TIMESTAMPTZ,
    ip_address INET NOT NULL
);

-- Create indexes for performance
\echo 'Creating auth indexes...'
CREATE INDEX IF NOT EXISTS users_email_partial_key ON auth.users (email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS users_instance_id_idx ON auth.users (instance_id);
CREATE INDEX IF NOT EXISTS refresh_tokens_instance_id_idx ON auth.refresh_tokens (instance_id);
CREATE INDEX IF NOT EXISTS refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens (instance_id, user_id);
CREATE INDEX IF NOT EXISTS refresh_tokens_parent_idx ON auth.refresh_tokens (parent);
CREATE INDEX IF NOT EXISTS refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens (session_id, revoked);
CREATE INDEX IF NOT EXISTS refresh_tokens_updated_at_idx ON auth.refresh_tokens (updated_at DESC);
CREATE INDEX IF NOT EXISTS audit_logs_instance_id_idx ON auth.audit_log_entries (instance_id);
CREATE INDEX IF NOT EXISTS flow_state_created_at_idx ON auth.flow_state (created_at DESC);
CREATE INDEX IF NOT EXISTS identities_email_idx ON auth.identities (email);
CREATE INDEX IF NOT EXISTS identities_user_id_idx ON auth.identities (user_id);
CREATE INDEX IF NOT EXISTS sessions_user_id_idx ON auth.sessions (user_id);
CREATE INDEX IF NOT EXISTS sessions_not_after_idx ON auth.sessions (not_after DESC);
CREATE INDEX IF NOT EXISTS mfa_amr_claims_session_id_idx ON auth.mfa_amr_claims (session_id);
CREATE INDEX IF NOT EXISTS mfa_factors_user_id_idx ON auth.mfa_factors (user_id);
CREATE INDEX IF NOT EXISTS mfa_challenges_created_at_idx ON auth.mfa_challenges (created_at DESC);

-- Create functions for auth
\echo 'Creating auth functions...'
CREATE OR REPLACE FUNCTION auth.uid()
RETURNS UUID
LANGUAGE SQL STABLE
AS $$
  SELECT
    COALESCE(
        current_setting('request.jwt.claim.sub', true),
        (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    )::uuid
$$;

CREATE OR REPLACE FUNCTION auth.role()
RETURNS TEXT
LANGUAGE SQL STABLE
AS $$
  SELECT
    COALESCE(
        current_setting('request.jwt.claim.role', true),
        (current_setting('request.jwt.claims', true)::jsonb ->> 'role')
    )::text
$$;

CREATE OR REPLACE FUNCTION auth.email()
RETURNS TEXT
LANGUAGE SQL STABLE
AS $$
  SELECT
    COALESCE(
        current_setting('request.jwt.claim.email', true),
        (current_setting('request.jwt.claims', true)::jsonb ->> 'email')
    )::text
$$;

\echo 'Auth schema setup completed successfully!'