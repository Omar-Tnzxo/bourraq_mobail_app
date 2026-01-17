-- Bourraq App - Database Schema
-- Authentication & User Management Tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- AREAS TABLE (Predefined service areas)
-- =====================================================
-- Create this FIRST because users table references it
CREATE TABLE IF NOT EXISTS public.areas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_ar VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    governorate VARCHAR(100) NOT NULL,
    
    -- Geofencing (radius-based circular area)
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    radius_km DECIMAL(5, 2), -- Service radius in kilometers
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert initial areas (6th of October City)
INSERT INTO public.areas (name_ar, name_en, city, governorate, latitude, longitude, radius_km) VALUES
('ابني بيتك 2', 'Ebny Beitak 2', '6th of October', 'Giza', 29.9500, 30.9200, 3.0),
('ابني بيتك 3', 'Ebny Beitak 3', '6th of October', 'Giza', 29.9520, 30.9220, 3.0),
('ابني بيتك 4', 'Ebny Beitak 4', '6th of October', 'Giza', 29.9540, 30.9240, 3.0),
('ابني بيتك 5', 'Ebny Beitak 5', '6th of October', 'Giza', 29.9560, 30.9260, 3.0),
('ابني بيتك 7', 'Ebny Beitak 7', '6th of October', 'Giza', 29.9580, 30.9280, 3.0),
('حدائق أكتوبر', 'Hadayek October', '6th of October', 'Giza', 29.9600, 30.9300, 4.0),
('دهشور', 'Dahshur', '6th of October', 'Giza', 29.9400, 30.9100, 3.5),
('ميليشيا', 'Militia', '6th of October', 'Giza', 29.9450, 30.9150, 3.0),
('كومباوند حورس', 'Horus Compound', '6th of October', 'Giza', 29.9480, 30.9180, 2.5),
('كومباوند دار مصر', 'Dar Misr Compound', '6th of October', 'Giza', 29.9550, 30.9250, 2.5),
('كومباوند ستان مصر', 'Stan Misr Compound', '6th of October', 'Giza', 29.9570, 30.9270, 2.0),
('مشروع 390 فدان', '390 Feddan Project', '6th of October', 'Giza', 29.9420, 30.9120, 4.0);

-- =====================================================
-- USERS TABLE (Main user profile data)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Profile Info
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    
    -- Location (selected from predefined areas)
    country VARCHAR(100) DEFAULT 'Egypt',
    currency VARCHAR(10) DEFAULT 'EGP',
    city VARCHAR(100),
    area_id UUID REFERENCES public.areas(id),
    
    -- Account Status
    is_active BOOLEAN DEFAULT TRUE,
    is_banned BOOLEAN DEFAULT FALSE,
    is_email_verified BOOLEAN DEFAULT FALSE,
    
    -- JWT Token (for backend validation)
    jwt_token TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE
);

-- Create indexes for faster queries
CREATE INDEX idx_users_auth_user_id ON public.users(auth_user_id);
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_phone ON public.users(phone);
CREATE INDEX idx_users_area_id ON public.users(area_id);

-- =====================================================
-- DELETED_USERS TABLE (Soft delete archive)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.deleted_users (
    id UUID PRIMARY KEY,
    auth_user_id UUID,
    name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    country VARCHAR(100),
    city VARCHAR(100),
    area_id UUID,
    is_banned BOOLEAN,
    deletion_reason TEXT,
    deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    original_created_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- OTP_VERIFICATIONS TABLE (Email OTP codes)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.otp_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    purpose VARCHAR(50) NOT NULL, -- 'registration', 'email_change', 'password_reset'
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_otp_email ON public.otp_verifications(email);
CREATE INDEX idx_otp_expires_at ON public.otp_verifications(expires_at);

-- =====================================================
-- AREA_REQUESTS TABLE (User requests for new areas)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.area_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    governorate VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    area_name VARCHAR(255) NOT NULL,
    additional_info TEXT,
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- USER_ADDRESSES TABLE (Delivery addresses)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- Address Type
    address_type VARCHAR(50) NOT NULL, -- 'apartment', 'villa', 'office'
    
    -- Location
    area_id UUID REFERENCES public.areas(id),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Address Details
    building_name VARCHAR(255),
    apartment_number VARCHAR(50),
    floor_number VARCHAR(50),
    street_name VARCHAR(255),
    landmark VARCHAR(255),
    address_label VARCHAR(100), -- e.g., "Home", "Work"
    
    phone VARCHAR(20), -- Can be different from user's main phone
    
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_user_addresses_user_id ON public.user_addresses(user_id);
CREATE INDEX idx_user_addresses_area_id ON public.user_addresses(area_id);

-- Function to enforce max 5 addresses per user
CREATE OR REPLACE FUNCTION check_max_addresses()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM public.user_addresses WHERE user_id = NEW.user_id) >= 5 THEN
        RAISE EXCEPTION 'Maximum 5 addresses allowed per user';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_max_addresses
    BEFORE INSERT ON public.user_addresses
    FOR EACH ROW
    EXECUTE FUNCTION check_max_addresses();

-- =====================================================
-- PHONE_NUMBER_TRACKING TABLE (Max 3 accounts per phone)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.phone_number_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) NOT NULL,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(phone, user_id)
);

CREATE INDEX idx_phone_tracking_phone ON public.phone_number_tracking(phone);

-- Function to enforce max 3 accounts per phone
CREATE OR REPLACE FUNCTION check_max_accounts_per_phone()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(DISTINCT user_id) FROM public.phone_number_tracking WHERE phone = NEW.phone) >= 3 THEN
        RAISE EXCEPTION 'Maximum 3 accounts allowed per phone number';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_max_phone_accounts
    BEFORE INSERT ON public.phone_number_tracking
    FOR EACH ROW
    EXECUTE FUNCTION check_max_accounts_per_phone();

-- Automatically add phone tracking when user is created
CREATE OR REPLACE FUNCTION auto_track_phone()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.phone_number_tracking (phone, user_id)
    VALUES (NEW.phone, NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER track_user_phone
    AFTER INSERT ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION auto_track_phone();

-- =====================================================
-- Update timestamps automatically
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
