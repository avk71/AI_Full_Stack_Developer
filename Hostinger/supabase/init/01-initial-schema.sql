-- =============================================
-- Supabase PostgreSQL 17 Initial Schema Setup
-- =============================================
-- This script sets up the complete Supabase schema for both relational and vector operations

\echo 'Starting Supabase PostgreSQL 17 schema initialization...'

-- Enable necessary extensions
\echo 'Creating extensions...'
CREATE EXTENSION IF NOT EXISTS "vector";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pgjwt";

-- Create auth schema and tables
\echo 'Creating auth schema...'
CREATE SCHEMA IF NOT EXISTS auth;

-- Create vectors schema for vector operations
\echo 'Creating vectors schema...'
CREATE SCHEMA IF NOT EXISTS vectors;
COMMENT ON SCHEMA vectors IS 'Schema for vector operations and embeddings storage';

-- Create basic auth tables
\echo 'Creating auth tables...'
CREATE TABLE IF NOT EXISTS auth.users (
    instance_id UUID,
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aud VARCHAR(255),
    role VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    encrypted_password VARCHAR(255),
    email_confirmed_at TIMESTAMPTZ,
    invited_at TIMESTAMPTZ,
    confirmation_token VARCHAR(255),
    confirmation_sent_at TIMESTAMPTZ,
    recovery_token VARCHAR(255),
    recovery_sent_at TIMESTAMPTZ,
    email_change_token_new VARCHAR(255),
    email_change VARCHAR(255),
    email_change_sent_at TIMESTAMPTZ,
    last_sign_in_at TIMESTAMPTZ,
    raw_app_meta_data JSONB,
    raw_user_meta_data JSONB,
    is_super_admin BOOLEAN,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    phone VARCHAR(255) UNIQUE DEFAULT NULL,
    phone_confirmed_at TIMESTAMPTZ DEFAULT NULL,
    phone_change VARCHAR(255) DEFAULT '',
    phone_change_token VARCHAR(255) DEFAULT '',
    phone_change_sent_at TIMESTAMPTZ DEFAULT NULL,
    confirmed_at TIMESTAMPTZ GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current VARCHAR(255) DEFAULT '',
    email_change_confirm_status SMALLINT DEFAULT 0,
    banned_until TIMESTAMPTZ DEFAULT NULL,
    reauthentication_token VARCHAR(255) DEFAULT '',
    reauthentication_sent_at TIMESTAMPTZ DEFAULT NULL,
    is_sso_user BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Create storage schema
\echo 'Creating storage schema...'
CREATE SCHEMA IF NOT EXISTS storage;

-- Create storage tables
\echo 'Creating storage tables...'
CREATE TABLE IF NOT EXISTS storage.buckets (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    owner UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    public BOOLEAN DEFAULT FALSE,
    avif_autodetection BOOLEAN DEFAULT FALSE,
    file_size_limit BIGINT DEFAULT NULL,
    allowed_mime_types TEXT[]
);

CREATE TABLE IF NOT EXISTS storage.objects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bucket_id TEXT REFERENCES storage.buckets(id),
    name TEXT NOT NULL,
    owner UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}',
    version TEXT DEFAULT '1'
);

-- Create realtime schema
\echo 'Creating realtime schema...'
CREATE SCHEMA IF NOT EXISTS _realtime;
CREATE SCHEMA IF NOT EXISTS realtime;

-- Create analytics schema for Logflare
\echo 'Creating analytics schema...'
CREATE SCHEMA IF NOT EXISTS _analytics;

-- Create graphql_public schema for GraphQL
\echo 'Creating GraphQL schema...'
CREATE SCHEMA IF NOT EXISTS graphql_public;

-- Create supabase_functions schema
\echo 'Creating functions schema...'
CREATE SCHEMA IF NOT EXISTS supabase_functions;

-- Create basic roles
\echo 'Creating roles...'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_admin') THEN
        CREATE ROLE supabase_admin;
    END IF;
END $$;

-- Grant basic permissions
\echo 'Setting up permissions...'
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA vectors TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA vectors TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA vectors TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA vectors TO anon, authenticated, service_role;
GRANT ALL ON SCHEMA auth TO supabase_admin;
GRANT ALL ON ALL TABLES IN SCHEMA auth TO supabase_admin;
GRANT ALL ON SCHEMA storage TO supabase_admin;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_admin;

-- Set default privileges
\echo 'Setting up default privileges...'
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA vectors GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA vectors GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA vectors GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

\echo 'Supabase PostgreSQL 17 initial schema setup completed successfully!'