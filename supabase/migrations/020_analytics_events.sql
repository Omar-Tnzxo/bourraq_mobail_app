-- =============================================
-- Analytics Events Table
-- Stores all custom analytics events from the app
-- =============================================

CREATE TABLE IF NOT EXISTS public.analytics_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  event_name text NOT NULL,
  event_params jsonb DEFAULT '{}',
  platform text CHECK (platform IN ('android', 'ios', 'web', 'unknown')),
  app_version text,
  session_id text,
  created_at timestamptz DEFAULT now()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_analytics_events_user ON analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_name ON analytics_events(event_name);
CREATE INDEX IF NOT EXISTS idx_analytics_events_created ON analytics_events(created_at DESC);

-- RLS Policies
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- Users can insert their own events
CREATE POLICY "Users can insert own analytics" ON analytics_events
  FOR INSERT
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- NOTE: Admins read analytics via service_role key (bypasses RLS)
-- If you have a user_roles table, you can add admin read policy later

-- Grant permissions
GRANT INSERT ON analytics_events TO authenticated;
GRANT INSERT ON analytics_events TO anon;

-- =============================================
-- Useful Analytics Views (Optional)
-- =============================================

-- Daily active users
CREATE OR REPLACE VIEW v_daily_active_users AS
SELECT 
  DATE(created_at) as date,
  COUNT(DISTINCT user_id) as active_users,
  COUNT(*) as total_events
FROM analytics_events
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Popular events
CREATE OR REPLACE VIEW v_popular_events AS
SELECT 
  event_name,
  COUNT(*) as count,
  COUNT(DISTINCT user_id) as unique_users
FROM analytics_events
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY event_name
ORDER BY count DESC;

-- Search analytics
CREATE OR REPLACE VIEW v_search_analytics AS
SELECT 
  event_params->>'search_term' as search_term,
  COUNT(*) as search_count,
  AVG((event_params->>'results_count')::int) as avg_results
FROM analytics_events
WHERE event_name = 'search'
  AND created_at > NOW() - INTERVAL '7 days'
GROUP BY event_params->>'search_term'
ORDER BY search_count DESC
LIMIT 100;

-- Product views
CREATE OR REPLACE VIEW v_product_views AS
SELECT 
  event_params->>'product_id' as product_id,
  event_params->>'product_name' as product_name,
  COUNT(*) as view_count,
  COUNT(DISTINCT user_id) as unique_viewers
FROM analytics_events
WHERE event_name = 'view_product'
  AND created_at > NOW() - INTERVAL '7 days'
GROUP BY event_params->>'product_id', event_params->>'product_name'
ORDER BY view_count DESC
LIMIT 50;

-- Purchase funnel
CREATE OR REPLACE VIEW v_purchase_funnel AS
SELECT 
  'add_to_cart' as step,
  1 as step_order,
  COUNT(DISTINCT user_id) as users
FROM analytics_events
WHERE event_name = 'add_to_cart'
  AND created_at > NOW() - INTERVAL '7 days'
UNION ALL
SELECT 
  'begin_checkout' as step,
  2 as step_order,
  COUNT(DISTINCT user_id) as users
FROM analytics_events
WHERE event_name = 'begin_checkout'
  AND created_at > NOW() - INTERVAL '7 days'
UNION ALL
SELECT 
  'purchase' as step,
  3 as step_order,
  COUNT(DISTINCT user_id) as users
FROM analytics_events
WHERE event_name = 'purchase'
  AND created_at > NOW() - INTERVAL '7 days'
ORDER BY step_order;
