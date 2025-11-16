-- =============================================
-- Sample Data and Development Seeds
-- =============================================
-- Optional sample data for development and testing

\echo 'Loading sample data...'

-- Sample data (uncomment and modify as needed for development)

-- Example: Sample vector collection
-- INSERT INTO vectors.collections (name, description, embedding_model, embedding_dimensions)
-- VALUES
--     ('documents', 'Document embeddings collection', 'text-embedding-ada-002', 1536),
--     ('faq', 'FAQ embeddings for chatbot', 'text-embedding-ada-002', 1536)
-- ON CONFLICT (name) DO NOTHING;

-- Example: Sample documents (after you have actual users)
-- INSERT INTO public.documents (title, content, owner_id, is_public, tags)
-- VALUES
--     ('Welcome Guide', 'Welcome to our platform! This is a getting started guide...',
--      'your-user-uuid-here', true, ARRAY['guide', 'welcome']),
--     ('API Documentation', 'This document describes our REST API endpoints...',
--      'your-user-uuid-here', true, ARRAY['api', 'docs'])
-- ON CONFLICT (id) DO NOTHING;

-- Example: Sample projects
-- INSERT INTO public.projects (name, description, owner_id, is_public, tags)
-- VALUES
--     ('Sample RAG Project', 'A sample project demonstrating RAG capabilities',
--      'your-user-uuid-here', true, ARRAY['rag', 'ai', 'demo']),
--     ('Vector Search Demo', 'Demonstration of vector similarity search',
--      'your-user-uuid-here', true, ARRAY['vector', 'search', 'demo'])
-- ON CONFLICT (id) DO NOTHING;

-- Example: Sample analytics events
-- INSERT INTO public.analytics_events (event_name, user_id, event_data)
-- VALUES
--     ('page_view', 'your-user-uuid-here', '{"page": "/dashboard", "duration": 15000}'),
--     ('search_query', 'your-user-uuid-here', '{"query": "vector database", "results": 10}')
-- ON CONFLICT (id) DO NOTHING;

\echo 'Sample data loading completed!'
\echo 'Note: Most sample data is commented out. Uncomment and customize as needed.'