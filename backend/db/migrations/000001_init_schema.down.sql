-- ============================================================================
-- ROLLBACK - DROP ALL TABLES AND TRIGGERS
-- ============================================================================
-- This migration rolls back the initial schema by dropping all tables
-- Migration: 000001_init_schema
-- Created: 2025-11-13

-- Drop triggers first
DROP TRIGGER IF EXISTS update_user_friendships_updated_at ON user_friendships;
DROP TRIGGER IF EXISTS update_comment_updated_at ON comment;
DROP TRIGGER IF EXISTS update_brew_updated_at ON brew;
DROP TRIGGER IF EXISTS update_post_updated_at ON post;
DROP TRIGGER IF EXISTS update_user_updated_at ON "user";

-- Drop trigger function
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS notification CASCADE;
DROP TABLE IF EXISTS post_user_tags CASCADE;
DROP TABLE IF EXISTS comment_likes CASCADE;
DROP TABLE IF EXISTS post_likes CASCADE;
DROP TABLE IF EXISTS user_friendships CASCADE;
DROP TABLE IF EXISTS comment CASCADE;
DROP TABLE IF EXISTS media CASCADE;
DROP TABLE IF EXISTS post CASCADE;
DROP TABLE IF EXISTS brew CASCADE;
DROP TABLE IF EXISTS "user" CASCADE;
