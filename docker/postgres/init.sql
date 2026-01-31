-- docker/postgres/init.sql
-- Complete Database Initialization Script

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "citext";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "postgis" CASCADE;

-- Create custom types
DO $$ 
BEGIN
    -- Event Types
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'event_type') THEN
        CREATE TYPE event_type AS ENUM (
            'Movie',
            'Concert',
            'Sports',
            'Theater',
            'Comedy',
            'Festival',
            'Conference',
            'Workshop',
            'Exhibition',
            'Party',
            'Seminar',
            'Charity',
            'Networking',
            'Competition',
            'Webinar',
            'Tour',
            'Meetup'
        );
    END IF;

    -- Event Status
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'event_status') THEN
        CREATE TYPE event_status AS ENUM (
            'Draft',
            'Pending',
            'Active',
            'SoldOut',
            'Cancelled',
            'Completed',
            'Postponed',
            'Archived',
            'Deleted'
        );
    END IF;

    -- Ticket Status
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ticket_status') THEN
        CREATE TYPE ticket_status AS ENUM (
            'Active',
            'Used',
            'Transferred',
            'Cancelled',
            'Expired',
            'OnResale',
            'Reserved',
            'Refunded',
            'Pending',
            'Locked'
        );
    END IF;

    -- Transfer Status
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transfer_status') THEN
        CREATE TYPE transfer_status AS ENUM (
            'Pending',
            'Completed',
            'Cancelled',
            'Expired',
            'Rejected',
            'Failed',
            'Processing'
        );
    END IF;

    -- Payment Status
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
        CREATE TYPE payment_status AS ENUM (
            'Pending',
            'Completed',
            'Failed',
            'Refunded',
            'PartiallyRefunded',
            'Disputed',
            'Chargeback'
        );
    END IF;

    -- Payment Method
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
        CREATE TYPE payment_method AS ENUM (
            'Card',
            'UPI',
            'NetBanking',
            'Wallet',
            'Cash',
            'BankTransfer',
            'PayLater',
            'Cryptocurrency'
        );
    END IF;

    -- User Role
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM (
            'SuperAdmin',
            'Admin',
            'Organizer',
            'VenueManager',
            'Support',
            'User',
            'Guest'
        );
    END IF;
END $$;

-- Create schema
CREATE SCHEMA IF NOT EXISTS eventbooking;
CREATE SCHEMA IF NOT EXISTS hangfire;

-- Set search path
SET search_path TO eventbooking, public;

-- Create timezone
SET TIMEZONE = 'UTC';

-- Create sequences
CREATE SEQUENCE IF NOT EXISTS ticket_number_seq
    START WITH 100000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 20;

CREATE SEQUENCE IF NOT EXISTS booking_number_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 20;

CREATE SEQUENCE IF NOT EXISTS transaction_number_seq
    START WITH 10000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 20;

-- Create functions
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to generate unique ticket number
CREATE OR REPLACE FUNCTION generate_ticket_number()
RETURNS TEXT AS $$
DECLARE
    next_val BIGINT;
    formatted_val TEXT;
BEGIN
    next_val := nextval('ticket_number_seq');
    formatted_val := 'TICKET-' || LPAD(next_val::TEXT, 8, '0');
    RETURN formatted_val;
END;
$$ LANGUAGE plpgsql;

-- Function to check seat availability
CREATE OR REPLACE FUNCTION check_seat_availability(
    p_event_id UUID,
    p_section_id UUID,
    p_seat_numbers TEXT[]
)
RETURNS TABLE (
    seat_number TEXT,
    is_available BOOLEAN,
    ticket_id UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.seat_number,
        CASE 
            WHEN t.id IS NULL OR t.status IN ('Cancelled', 'Refunded') THEN TRUE
            ELSE FALSE
        END as is_available,
        t.id as ticket_id
    FROM 
        unnest(p_seat_numbers) as s(seat_number)
    LEFT JOIN eventbooking.tickets t ON 
        t.event_id = p_event_id 
        AND t.section_id = p_section_id
        AND t.seat_number = s.seat_number
        AND t.status NOT IN ('Cancelled', 'Refunded');
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to calculate event revenue
CREATE OR REPLACE FUNCTION calculate_event_revenue(p_event_id UUID)
RETURNS DECIMAL(12,2) AS $$
DECLARE
    total_revenue DECIMAL(12,2);
BEGIN
    SELECT COALESCE(SUM(p.amount), 0)
    INTO total_revenue
    FROM eventbooking.payments p
    INNER JOIN eventbooking.bookings b ON p.booking_id = b.id
    INNER JOIN eventbooking.tickets t ON b.id = t.booking_id
    WHERE t.event_id = p_event_id
    AND p.status = 'Completed';
    
    RETURN total_revenue;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to get user ticket statistics
CREATE OR REPLACE FUNCTION get_user_ticket_stats(p_user_id UUID)
RETURNS TABLE (
    total_tickets INT,
    upcoming_events INT,
    past_events INT,
    total_spent DECIMAL(12,2),
    favorite_category TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT t.id)::INT as total_tickets,
        COUNT(DISTINCT CASE WHEN e.start_datetime > NOW() THEN t.id END)::INT as upcoming_events,
        COUNT(DISTINCT CASE WHEN e.start_datetime <= NOW() THEN t.id END)::INT as past_events,
        COALESCE(SUM(CASE WHEN p.status = 'Completed' THEN p.amount ELSE 0 END), 0) as total_spent,
        (
            SELECT e2.category
            FROM eventbooking.tickets t2
            INNER JOIN eventbooking.events e2 ON t2.event_id = e2.id
            WHERE t2.current_owner_id = p_user_id
            GROUP BY e2.category
            ORDER BY COUNT(*) DESC
            LIMIT 1
        ) as favorite_category
    FROM eventbooking.tickets t
    LEFT JOIN eventbooking.bookings b ON t.booking_id = b.id
    LEFT JOIN eventbooking.payments p ON b.id = p.booking_id
    INNER JOIN eventbooking.events e ON t.event_id = e.id
    WHERE t.current_owner_id = p_user_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- Set permissions
GRANT USAGE ON SCHEMA eventbooking TO eventbooking;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA eventbooking TO eventbooking;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA eventbooking TO eventbooking;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA eventbooking TO eventbooking;

-- Grant Hangfire schema permissions
GRANT USAGE ON SCHEMA hangfire TO eventbooking;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA hangfire TO eventbooking;

-- Set default permissions for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA eventbooking 
    GRANT ALL PRIVILEGES ON TABLES TO eventbooking;

ALTER DEFAULT PRIVILEGES IN SCHEMA eventbooking 
    GRANT ALL PRIVILEGES ON SEQUENCES TO eventbooking;

ALTER DEFAULT PRIVILEGES IN SCHEMA eventbooking 
    GRANT EXECUTE ON FUNCTIONS TO eventbooking;

-- Create read-only user for analytics
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'eventbooking_readonly') THEN
        CREATE USER eventbooking_readonly WITH PASSWORD 'ReadOnlyPassword123!';
    END IF;
END $$;

GRANT CONNECT ON DATABASE EventBookingDb TO eventbooking_readonly;
GRANT USAGE ON SCHEMA eventbooking TO eventbooking_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA eventbooking TO eventbooking_readonly;

-- Enable row level security for sensitive tables
ALTER TABLE eventbooking.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE eventbooking.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE eventbooking.ticket_transfers ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY payments_select_policy ON eventbooking.payments
    FOR SELECT USING (
        -- Users can see their own payments
        EXISTS (
            SELECT 1 FROM eventbooking.bookings b
            WHERE b.id = payments.booking_id 
            AND b.user_id = current_setting('app.current_user_id', true)::UUID
        )
        OR
        -- Admins can see all payments
        EXISTS (
            SELECT 1 FROM eventbooking.users u
            WHERE u.id = current_setting('app.current_user_id', true)::UUID
            AND u.role = 'Admin'
        )
    );

-- Set statistics
ALTER DATABASE EventBookingDb SET default_statistics_target = 100;
ALTER DATABASE EventBookingDb SET random_page_cost = 1.1;
ALTER DATABASE EventBookingDb SET effective_cache_size = '4GB';

-- Create index advisor extension
CREATE EXTENSION IF NOT EXISTS hypopg;

-- Vacuum and analyze
VACUUM ANALYZE;