-- Seed data for testing

-- Create a sample user profile (you'll need to create the auth user first via Supabase Studio)
-- This is just for reference - actual user creation should be done through Supabase Auth

-- =============================================
-- Sample Data and User Profiles Setup
-- =============================================
-- This file creates sample tables for your relational data needs

\echo 'Creating sample relational database tables...'

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

COMMENT ON TABLE public.users_profile IS 'Extended user profile information';

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
    settings JSONB DEFAULT '{}',
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

COMMENT ON TABLE public.projects IS 'User projects with relational and JSON data';

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

-- Example table for time-series data
CREATE TABLE IF NOT EXISTS public.analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name VARCHAR(100) NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    event_data JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

COMMENT ON TABLE public.analytics_events IS 'Analytics and event tracking';

-- Index for time-series queries
CREATE INDEX IF NOT EXISTS analytics_events_created_at_idx ON public.analytics_events (created_at DESC);
CREATE INDEX IF NOT EXISTS analytics_events_user_id_idx ON public.analytics_events (user_id);
CREATE INDEX IF NOT EXISTS analytics_events_project_id_idx ON public.analytics_events (project_id);
CREATE INDEX IF NOT EXISTS analytics_events_event_name_idx ON public.analytics_events (event_name);

-- RLS for analytics events
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own events" ON public.analytics_events
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own events" ON public.analytics_events
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Example table for documents/files metadata
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT,
    file_path TEXT,
    file_size BIGINT,
    mime_type VARCHAR(255),
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
    is_public BOOLEAN DEFAULT FALSE,
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

COMMENT ON TABLE public.documents IS 'Document metadata and content (pairs with vector embeddings)';

-- Indexes for documents
CREATE INDEX IF NOT EXISTS documents_owner_id_idx ON public.documents (owner_id);
CREATE INDEX IF NOT EXISTS documents_project_id_idx ON public.documents (project_id);
CREATE INDEX IF NOT EXISTS documents_created_at_idx ON public.documents (created_at DESC);
CREATE INDEX IF NOT EXISTS documents_tags_gin_idx ON public.documents USING gin (tags);
CREATE INDEX IF NOT EXISTS documents_metadata_gin_idx ON public.documents USING gin (metadata);

-- RLS for documents
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own documents" ON public.documents
    FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Users can view public documents" ON public.documents
    FOR SELECT USING (is_public = TRUE);

CREATE POLICY "Users can insert own documents" ON public.documents
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own documents" ON public.documents
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own documents" ON public.documents
    FOR DELETE USING (auth.uid() = owner_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_users_profile_updated_at BEFORE UPDATE ON public.users_profile FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON public.documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add updated_at trigger to vectors.embeddings
CREATE TRIGGER update_vectors_embeddings_updated_at BEFORE UPDATE ON vectors.embeddings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vectors_collections_updated_at BEFORE UPDATE ON vectors.collections FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

\echo 'Sample relational database tables created successfully!'
\echo 'Tables created: users_profile, projects, analytics_events, documents'
\echo 'All tables have Row Level Security (RLS) enabled'

-- Insert sample vector documents
INSERT INTO vectors.documents (content, metadata, embedding) VALUES
('This is a sample document about machine learning', '{"category": "AI", "tags": ["ML", "AI"]}', null),
('This document discusses database optimization techniques', '{"category": "Database", "tags": ["PostgreSQL", "Performance"]}', null),
('A guide to building web applications with modern frameworks', '{"category": "Web", "tags": ["JavaScript", "React", "Vue"]}', null);

-- Note: The embeddings are set to null initially. You would populate these with actual
-- vector embeddings from your AI model (like OpenAI embeddings) in your application code.

-- Create some useful functions for database management

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add update triggers to tables
CREATE TRIGGER update_users_profile_updated_at BEFORE UPDATE ON public.users_profile
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON vectors.documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();