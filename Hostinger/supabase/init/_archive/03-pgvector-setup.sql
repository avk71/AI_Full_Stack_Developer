-- Install pgvector extension for vector operations
CREATE EXTENSION IF NOT EXISTS vector;

-- Create a dedicated schema for vector operations
CREATE SCHEMA IF NOT EXISTS vectors;

-- Grant permissions on vectors schema
GRANT USAGE ON SCHEMA vectors TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA vectors TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA vectors TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA vectors TO anon, authenticated, service_role;

-- Set default privileges for vectors schema
ALTER DEFAULT PRIVILEGES IN SCHEMA vectors GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA vectors GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA vectors GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- Example vector table for embeddings
CREATE TABLE IF NOT EXISTS vectors.documents (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    embedding vector(1536), -- OpenAI embedding dimensions
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create index for vector similarity search
CREATE INDEX IF NOT EXISTS documents_embedding_idx ON vectors.documents
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Function to search similar documents
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

-- Example table for general relational data
CREATE TABLE IF NOT EXISTS public.users_profile (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    website TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS policies for users_profile
ALTER TABLE public.users_profile ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON public.users_profile
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON public.users_profile
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON public.users_profile
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Example table for application data
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS policies for projects
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own projects" ON public.projects
    FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Users can view public projects" ON public.projects
    FOR SELECT USING (is_public = TRUE);

CREATE POLICY "Users can insert own projects" ON public.projects
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own projects" ON public.projects
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own projects" ON public.projects
    FOR DELETE USING (auth.uid() = owner_id);