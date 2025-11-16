-- =============================================
-- Test Script to Verify Supabase Init Scripts Execution
-- =============================================
-- Run this script to verify all init scripts executed successfully

\echo '================================================='
\echo 'Testing Supabase Init Scripts Execution'
\echo '================================================='

-- Test 1: Check if all required schemas exist
\echo ''
\echo 'TEST 1: Checking required schemas...'
SELECT schema_name,
       CASE
           WHEN schema_name IN ('auth', 'storage', 'vectors', '_realtime', '_analytics', 'graphql_public', 'supabase_functions')
           THEN '✅ FOUND'
           ELSE '❌ MISSING'
       END as status
FROM information_schema.schemata
WHERE schema_name IN ('auth', 'storage', 'vectors', '_realtime', '_analytics', 'graphql_public', 'supabase_functions')
ORDER BY schema_name;

-- Test 2: Check if vector extension is installed
\echo ''
\echo 'TEST 2: Checking pgvector extension...'
SELECT extname as extension_name,
       '✅ INSTALLED' as status
FROM pg_extension
WHERE extname = 'vector'
UNION ALL
SELECT 'vector' as extension_name,
       '❌ NOT INSTALLED' as status
WHERE NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector');

-- Test 3: Check auth tables (from 02-auth-schema.sql)
\echo ''
\echo 'TEST 3: Checking auth tables...'
SELECT table_name,
       '✅ EXISTS' as status
FROM information_schema.tables
WHERE table_schema = 'auth'
  AND table_name IN ('users', 'refresh_tokens', 'sessions', 'mfa_factors', 'identities')
ORDER BY table_name;

-- Test 4: Check storage tables (from 03-storage-schema.sql)
\echo ''
\echo 'TEST 4: Checking storage tables...'
SELECT table_name,
       '✅ EXISTS' as status
FROM information_schema.tables
WHERE table_schema = 'storage'
  AND table_name IN ('buckets', 'objects')
ORDER BY table_name;

-- Test 5: Check vector tables (from 04-vector-schema.sql)
\echo ''
\echo 'TEST 5: Checking vector tables...'
SELECT table_name,
       '✅ EXISTS' as status
FROM information_schema.tables
WHERE table_schema = 'vectors'
  AND table_name IN ('embeddings', 'collections', 'documents')
ORDER BY table_name;

-- Test 6: Check vector search functions
\echo ''
\echo 'TEST 6: Checking vector search functions...'
SELECT routine_name,
       '✅ EXISTS' as status
FROM information_schema.routines
WHERE routine_schema = 'vectors'
  AND routine_name IN ('search_embeddings_cosine', 'search_embeddings_l2', 'match_documents')
ORDER BY routine_name;

-- Test 7: Check auth functions
\echo ''
\echo 'TEST 7: Checking auth functions...'
SELECT routine_name,
       '✅ EXISTS' as status
FROM information_schema.routines
WHERE routine_schema = 'auth'
  AND routine_name IN ('uid', 'role', 'email')
ORDER BY routine_name;

-- Test 8: Check storage functions
\echo ''
\echo 'TEST 8: Checking storage functions...'
SELECT routine_name,
       '✅ EXISTS' as status
FROM information_schema.routines
WHERE routine_schema = 'storage'
  AND routine_name IN ('folder_path', 'filename', 'dirname', 'extension')
ORDER BY routine_name;

-- Test 9: Check if default collections exist
\echo ''
\echo 'TEST 9: Checking default vector collection...'
SELECT name,
       '✅ EXISTS' as status
FROM vectors.collections
WHERE name = 'default'
UNION ALL
SELECT 'default' as name,
       '❌ MISSING' as status
WHERE NOT EXISTS (SELECT 1 FROM vectors.collections WHERE name = 'default');

-- Test 10: Check if default storage buckets exist
\echo ''
\echo 'TEST 10: Checking default storage buckets...'
SELECT id,
       public,
       '✅ EXISTS' as status
FROM storage.buckets
WHERE id IN ('avatars', 'documents')
ORDER BY id;

-- Test 11: Check RLS (Row Level Security) is enabled
\echo ''
\echo 'TEST 11: Checking RLS on critical tables...'
SELECT schemaname || '.' || tablename as table_name,
       CASE WHEN rowsecurity THEN '✅ ENABLED' ELSE '❌ DISABLED' END as rls_status
FROM pg_tables
WHERE schemaname IN ('vectors', 'storage')
  AND tablename IN ('embeddings', 'collections', 'buckets', 'objects')
ORDER BY table_name;

-- Test 12: Check if sample data exists (optional)
\echo ''
\echo 'TEST 12: Checking sample data (optional)...'
SELECT 'vectors.documents' as table_name,
       COUNT(*) as row_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE 'ℹ️ EMPTY (OK)' END as status
FROM vectors.documents;

-- Summary
\echo ''
\echo '================================================='
\echo 'SUMMARY: If you see mostly ✅ symbols above, your'
\echo 'init scripts executed successfully!'
\echo '================================================='

-- Quick count of all tables created
\echo ''
\echo 'TOTAL TABLES CREATED:'
SELECT schema_name, COUNT(*) as table_count
FROM information_schema.tables
WHERE table_schema IN ('auth', 'storage', 'vectors', 'public')
  AND table_type = 'BASE TABLE'
GROUP BY schema_name
ORDER BY schema_name;