-- =============================================
-- Create supabase_admin user with proper credentials
-- =============================================
-- This script creates the supabase_admin user needed by realtime service
-- Note: This script is executed before other init scripts (00- prefix)

\echo 'Starting supabase_admin user creation...'

-- Drop user if exists (for clean reinstall)
DROP USER IF EXISTS supabase_admin;

-- Create supabase_admin user first
CREATE USER supabase_admin WITH SUPERUSER;

-- Set the password from SUPABASE_ADMIN_PASSWORD environment variable
-- This will be different from the postgres user password
\set admin_password `echo "$SUPABASE_ADMIN_PASSWORD"`
ALTER USER supabase_admin WITH PASSWORD :'admin_password';

\echo 'supabase_admin user created successfully!'
\echo 'User: supabase_admin with SUPERUSER privileges'
\echo 'Password: set from SUPABASE_ADMIN_PASSWORD environment variable';