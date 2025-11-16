-- =============================================
-- Supabase Storage Schema Setup
-- =============================================
-- Storage schema setup for Supabase file storage

\echo 'Setting up storage schema...'

-- Create storage schema if not exists (should already exist)
CREATE SCHEMA IF NOT EXISTS storage;

-- Create additional storage functions
\echo 'Creating storage functions...'

CREATE OR REPLACE FUNCTION storage.folder_path(name text)
RETURNS text[]
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT string_to_array(name, '/')
$$;

CREATE OR REPLACE FUNCTION storage.filename(name text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT (string_to_array(name, '/'))[(array_length(string_to_array(name, '/'), 1))]
$$;

CREATE OR REPLACE FUNCTION storage.dirname(name text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE
        WHEN array_length(string_to_array(name, '/'), 1) > 1
        THEN array_to_string((string_to_array(name, '/'))[1:(array_length(string_to_array(name, '/'), 1) - 1)], '/')
        ELSE ''
    END
$$;

CREATE OR REPLACE FUNCTION storage.extension(name text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT reverse(split_part(reverse(storage.filename(name)), '.', 1))
$$;

-- RLS policies for storage
\echo 'Setting up storage RLS policies...'

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Default bucket policies (you can customize these)
CREATE POLICY "Public buckets are viewable by everyone"
ON storage.buckets FOR SELECT
TO public
USING (public = true);

CREATE POLICY "Users can view their own buckets"
ON storage.buckets FOR SELECT
TO authenticated
USING (owner = auth.uid());

CREATE POLICY "Users can create their own buckets"
ON storage.buckets FOR INSERT
TO authenticated
WITH CHECK (owner = auth.uid());

CREATE POLICY "Users can update their own buckets"
ON storage.buckets FOR UPDATE
TO authenticated
USING (owner = auth.uid())
WITH CHECK (owner = auth.uid());

CREATE POLICY "Users can delete their own buckets"
ON storage.buckets FOR DELETE
TO authenticated
USING (owner = auth.uid());

-- Object policies
CREATE POLICY "Public objects in public buckets are viewable by everyone"
ON storage.objects FOR SELECT
TO public
USING (
    bucket_id IN (
        SELECT id FROM storage.buckets WHERE public = true
    )
);

CREATE POLICY "Users can view their own objects"
ON storage.objects FOR SELECT
TO authenticated
USING (owner = auth.uid());

CREATE POLICY "Users can upload objects to their buckets"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id IN (
        SELECT id FROM storage.buckets WHERE owner = auth.uid()
    )
);

CREATE POLICY "Users can update their own objects"
ON storage.objects FOR UPDATE
TO authenticated
USING (owner = auth.uid())
WITH CHECK (owner = auth.uid());

CREATE POLICY "Users can delete their own objects"
ON storage.objects FOR DELETE
TO authenticated
USING (owner = auth.uid());

-- Create storage indexes for performance
\echo 'Creating storage indexes...'
CREATE INDEX IF NOT EXISTS buckets_owner_idx ON storage.buckets (owner);
CREATE INDEX IF NOT EXISTS objects_bucket_id_idx ON storage.objects (bucket_id);
CREATE INDEX IF NOT EXISTS objects_owner_idx ON storage.objects (owner);
CREATE INDEX IF NOT EXISTS objects_bucket_id_name_idx ON storage.objects (bucket_id, name);

-- Insert default public bucket
\echo 'Creating default storage buckets...'
INSERT INTO storage.buckets (id, name, public)
VALUES
    ('avatars', 'avatars', true),
    ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

\echo 'Storage schema setup completed successfully!'