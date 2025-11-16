-- =============================================
-- Vector Operations Schema Setup (PostgreSQL 17 + pgvector)
-- =============================================
-- This sets up the vectors schema for AI/ML operations with embeddings

\echo 'Setting up vector operations schema...'

-- Enable vector extension (should already be enabled from 01-initial-schema.sql)
CREATE EXTENSION IF NOT EXISTS vector;

-- Create vectors schema (should already exist)
CREATE SCHEMA IF NOT EXISTS vectors;
COMMENT ON SCHEMA vectors IS 'Schema for AI/ML vector operations and embeddings storage';

-- Set search path to include vectors schema
SET search_path TO vectors, public;

-- Create embeddings table for storing document/text embeddings
\echo 'Creating embeddings tables...'

CREATE TABLE IF NOT EXISTS vectors.embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content TEXT NOT NULL,
    embedding vector(1536), -- OpenAI ada-002 embedding size, adjust as needed
    metadata JSONB DEFAULT '{}',
    source_type VARCHAR(50) DEFAULT 'text', -- text, document, image, etc.
    source_url TEXT,
    source_id TEXT,
    chunk_index INTEGER DEFAULT 0,
    tokens_count INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    owner_id UUID REFERENCES auth.users(id),
    collection_name VARCHAR(255) DEFAULT 'default'
);

COMMENT ON TABLE vectors.embeddings IS 'Storage for AI/ML embeddings with vector similarity search';
COMMENT ON COLUMN vectors.embeddings.embedding IS 'Vector embedding for similarity search';
COMMENT ON COLUMN vectors.embeddings.metadata IS 'Additional metadata about the embedded content';
COMMENT ON COLUMN vectors.embeddings.collection_name IS 'Group embeddings by collection/project';

-- Create collections table to organize embeddings
CREATE TABLE IF NOT EXISTS vectors.collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    embedding_model VARCHAR(100) DEFAULT 'text-embedding-ada-002',
    embedding_dimensions INTEGER DEFAULT 1536,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    owner_id UUID REFERENCES auth.users(id),
    metadata JSONB DEFAULT '{}'
);

COMMENT ON TABLE vectors.collections IS 'Collections to organize embeddings by project or use case';

-- Add foreign key constraint for collection
ALTER TABLE vectors.embeddings
ADD CONSTRAINT fk_embeddings_collection
FOREIGN KEY (collection_name) REFERENCES vectors.collections(name) ON DELETE SET NULL;

-- Keep the legacy documents table for backward compatibility
-- This is from the original setup - you can use either table structure
CREATE TABLE IF NOT EXISTS vectors.documents (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    embedding vector(1536), -- OpenAI embedding dimensions
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create vector search functions
\echo 'Creating vector search functions...'

-- Function for cosine similarity search (new table)
CREATE OR REPLACE FUNCTION vectors.search_embeddings_cosine(
    query_embedding vector(1536),
    match_count integer DEFAULT 5,
    filter_collection text DEFAULT NULL,
    filter_metadata jsonb DEFAULT NULL
)
RETURNS TABLE (
    id uuid,
    content text,
    similarity float,
    metadata jsonb,
    source_type varchar(50),
    source_url text,
    collection_name varchar(255)
)
LANGUAGE sql STABLE
AS $$
    SELECT
        e.id,
        e.content,
        1 - (e.embedding <=> query_embedding) as similarity,
        e.metadata,
        e.source_type,
        e.source_url,
        e.collection_name
    FROM vectors.embeddings e
    WHERE
        (filter_collection IS NULL OR e.collection_name = filter_collection)
        AND (filter_metadata IS NULL OR e.metadata @> filter_metadata)
    ORDER BY e.embedding <=> query_embedding
    LIMIT match_count;
$$;

-- Legacy function for backward compatibility (documents table)
CREATE OR REPLACE FUNCTION vectors.match_documents (
  query_embedding vector(1536),
  similarity_threshold float = 0.78,
  match_count int = 5
)
RETURNS TABLE (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    documents.id,
    documents.content,
    documents.metadata,
    1 - (documents.embedding <=> query_embedding) AS similarity
  FROM vectors.documents
  WHERE 1 - (documents.embedding <=> query_embedding) > similarity_threshold
  ORDER BY documents.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- Function for L2 (Euclidean) distance search
CREATE OR REPLACE FUNCTION vectors.search_embeddings_l2(
    query_embedding vector(1536),
    match_count integer DEFAULT 5,
    filter_collection text DEFAULT NULL,
    filter_metadata jsonb DEFAULT NULL
)
RETURNS TABLE (
    id uuid,
    content text,
    distance float,
    metadata jsonb,
    source_type varchar(50),
    source_url text,
    collection_name varchar(255)
)
LANGUAGE sql STABLE
AS $$
    SELECT
        e.id,
        e.content,
        e.embedding <-> query_embedding as distance,
        e.metadata,
        e.source_type,
        e.source_url,
        e.collection_name
    FROM vectors.embeddings e
    WHERE
        (filter_collection IS NULL OR e.collection_name = filter_collection)
        AND (filter_metadata IS NULL OR e.metadata @> filter_metadata)
    ORDER BY e.embedding <-> query_embedding
    LIMIT match_count;
$$;

-- Function for inner product (dot product) search
CREATE OR REPLACE FUNCTION vectors.search_embeddings_inner_product(
    query_embedding vector(1536),
    match_count integer DEFAULT 5,
    filter_collection text DEFAULT NULL,
    filter_metadata jsonb DEFAULT NULL
)
RETURNS TABLE (
    id uuid,
    content text,
    inner_product float,
    metadata jsonb,
    source_type varchar(50),
    source_url text,
    collection_name varchar(255)
)
LANGUAGE sql STABLE
AS $$
    SELECT
        e.id,
        e.content,
        (e.embedding <#> query_embedding) * -1 as inner_product,
        e.metadata,
        e.source_type,
        e.source_url,
        e.collection_name
    FROM vectors.embeddings e
    WHERE
        (filter_collection IS NULL OR e.collection_name = filter_collection)
        AND (filter_metadata IS NULL OR e.metadata @> filter_metadata)
    ORDER BY e.embedding <#> query_embedding
    LIMIT match_count;
$$;

-- Function to get collection statistics
CREATE OR REPLACE FUNCTION vectors.get_collection_stats(collection_name text)
RETURNS TABLE (
    total_embeddings bigint,
    avg_tokens numeric,
    total_tokens bigint,
    earliest_created timestamptz,
    latest_created timestamptz
)
LANGUAGE sql STABLE
AS $$
    SELECT
        COUNT(*) as total_embeddings,
        AVG(tokens_count) as avg_tokens,
        SUM(tokens_count) as total_tokens,
        MIN(created_at) as earliest_created,
        MAX(created_at) as latest_created
    FROM vectors.embeddings e
    WHERE e.collection_name = get_collection_stats.collection_name;
$$;

-- Create indexes for performance
\echo 'Creating vector indexes...'

-- Vector similarity indexes (pgvector indexes) for new embeddings table
CREATE INDEX IF NOT EXISTS embeddings_embedding_cosine_idx
ON vectors.embeddings USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

CREATE INDEX IF NOT EXISTS embeddings_embedding_l2_idx
ON vectors.embeddings USING ivfflat (embedding vector_l2_ops)
WITH (lists = 100);

CREATE INDEX IF NOT EXISTS embeddings_embedding_ip_idx
ON vectors.embeddings USING ivfflat (embedding vector_ip_ops)
WITH (lists = 100);

-- Legacy documents table index
CREATE INDEX IF NOT EXISTS documents_embedding_idx ON vectors.documents
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Regular indexes for new embeddings table
CREATE INDEX IF NOT EXISTS embeddings_collection_name_idx ON vectors.embeddings (collection_name);
CREATE INDEX IF NOT EXISTS embeddings_source_type_idx ON vectors.embeddings (source_type);
CREATE INDEX IF NOT EXISTS embeddings_owner_id_idx ON vectors.embeddings (owner_id);
CREATE INDEX IF NOT EXISTS embeddings_created_at_idx ON vectors.embeddings (created_at DESC);
CREATE INDEX IF NOT EXISTS embeddings_metadata_gin_idx ON vectors.embeddings USING gin (metadata);
CREATE INDEX IF NOT EXISTS embeddings_source_id_idx ON vectors.embeddings (source_id) WHERE source_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS collections_name_idx ON vectors.collections (name);
CREATE INDEX IF NOT EXISTS collections_owner_id_idx ON vectors.collections (owner_id);

-- Enable RLS (Row Level Security) for vectors tables
\echo 'Setting up vector RLS policies...'

ALTER TABLE vectors.embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE vectors.collections ENABLE ROW LEVEL SECURITY;

-- Collections policies
CREATE POLICY "Users can view their own collections"
ON vectors.collections FOR SELECT
TO authenticated
USING (owner_id = auth.uid());

CREATE POLICY "Users can create their own collections"
ON vectors.collections FOR INSERT
TO authenticated
WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can update their own collections"
ON vectors.collections FOR UPDATE
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can delete their own collections"
ON vectors.collections FOR DELETE
TO authenticated
USING (owner_id = auth.uid());

-- Service role has full access to collections
CREATE POLICY "Service role has full access to collections"
ON vectors.collections FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Embeddings policies
CREATE POLICY "Users can view their own embeddings"
ON vectors.embeddings FOR SELECT
TO authenticated
USING (owner_id = auth.uid());

CREATE POLICY "Users can create their own embeddings"
ON vectors.embeddings FOR INSERT
TO authenticated
WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can update their own embeddings"
ON vectors.embeddings FOR UPDATE
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can delete their own embeddings"
ON vectors.embeddings FOR DELETE
TO authenticated
USING (owner_id = auth.uid());

-- Service role has full access to embeddings
CREATE POLICY "Service role has full access to embeddings"
ON vectors.embeddings FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Anonymous users can search embeddings (read-only)
CREATE POLICY "Anonymous users can search embeddings"
ON vectors.embeddings FOR SELECT
TO anon
USING (true);

-- Create default collection
\echo 'Creating default vector collection...'
INSERT INTO vectors.collections (name, description, embedding_model, embedding_dimensions)
VALUES ('default', 'Default collection for embeddings', 'text-embedding-ada-002', 1536)
ON CONFLICT (name) DO NOTHING;

-- Grant permissions on vectors schema
\echo 'Setting up vector schema permissions...'
GRANT USAGE ON SCHEMA vectors TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA vectors TO authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA vectors TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA vectors TO authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA vectors TO authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA vectors TO anon;

-- Set default privileges for future objects in vectors schema
ALTER DEFAULT PRIVILEGES IN SCHEMA vectors GRANT ALL ON TABLES TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA vectors GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA vectors GRANT ALL ON SEQUENCES TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA vectors GRANT ALL ON FUNCTIONS TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA vectors GRANT EXECUTE ON FUNCTIONS TO anon;

\echo 'Vector operations schema setup completed successfully!'
\echo 'You can now store and search embeddings using cosine similarity, L2 distance, or inner product.'
\echo 'Use the vectors.search_embeddings_cosine() function for similarity searches.'