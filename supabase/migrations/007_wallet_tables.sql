-- ============================================
-- Bourraq - Wallet Tables Migration
-- Version: 007
-- Date: 2026-01-13
-- ============================================

-- ============================================
-- 1. Wallets Table
-- ============================================
CREATE TABLE IF NOT EXISTS public.wallets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    balance DECIMAL(12, 2) DEFAULT 0.00 NOT NULL CHECK (balance >= 0),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON public.wallets(user_id);

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_wallets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_wallets_updated_at ON public.wallets;
CREATE TRIGGER trigger_wallets_updated_at
    BEFORE UPDATE ON public.wallets
    FOR EACH ROW
    EXECUTE FUNCTION update_wallets_updated_at();

-- ============================================
-- 2. Wallet Transactions Table
-- ============================================
CREATE TYPE transaction_type AS ENUM ('deposit', 'withdrawal', 'refund', 'payment');

CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    wallet_id UUID REFERENCES public.wallets(id) ON DELETE CASCADE NOT NULL,
    type transaction_type NOT NULL,
    amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    balance_after DECIMAL(12, 2) NOT NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet_id ON public.wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON public.wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_order_id ON public.wallet_transactions(order_id) WHERE order_id IS NOT NULL;

-- ============================================
-- 3. Saved Cards Table
-- ============================================
CREATE TABLE IF NOT EXISTS public.saved_cards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    card_token TEXT NOT NULL,  -- PayMob token (NEVER store actual card data)
    last_four_digits CHAR(4) NOT NULL,
    card_brand VARCHAR(20) NOT NULL DEFAULT 'VISA',
    card_label VARCHAR(100),
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_saved_cards_user_id ON public.saved_cards(user_id);

-- Ensure only one default card per user
CREATE UNIQUE INDEX IF NOT EXISTS idx_saved_cards_user_default 
ON public.saved_cards(user_id) WHERE is_default = true;

-- ============================================
-- 4. RLS Policies
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_cards ENABLE ROW LEVEL SECURITY;

-- Wallets Policies
CREATE POLICY "Users can view their own wallet"
    ON public.wallets FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own wallet"
    ON public.wallets FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own wallet"
    ON public.wallets FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Wallet Transactions Policies
CREATE POLICY "Users can view their own transactions"
    ON public.wallet_transactions FOR SELECT
    USING (wallet_id IN (
        SELECT id FROM public.wallets WHERE user_id = auth.uid()
    ));

CREATE POLICY "Users can create transactions for their wallet"
    ON public.wallet_transactions FOR INSERT
    WITH CHECK (wallet_id IN (
        SELECT id FROM public.wallets WHERE user_id = auth.uid()
    ));

-- Saved Cards Policies
CREATE POLICY "Users can view their own cards"
    ON public.saved_cards FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can add their own cards"
    ON public.saved_cards FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cards"
    ON public.saved_cards FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cards"
    ON public.saved_cards FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- 5. Auto-create wallet for new users (Optional Trigger)
-- ============================================
CREATE OR REPLACE FUNCTION public.create_wallet_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.wallets (user_id, balance)
    VALUES (NEW.id, 0.00)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on users table (auth.users) - may need to be run by admin
-- DROP TRIGGER IF EXISTS trigger_create_wallet_on_signup ON auth.users;
-- CREATE TRIGGER trigger_create_wallet_on_signup
--     AFTER INSERT ON auth.users
--     FOR EACH ROW
--     EXECUTE FUNCTION public.create_wallet_for_new_user();

-- ============================================
-- 6. Comments for Documentation
-- ============================================
COMMENT ON TABLE public.wallets IS 'User wallet balances';
COMMENT ON TABLE public.wallet_transactions IS 'History of all wallet transactions (deposits, payments, refunds)';
COMMENT ON TABLE public.saved_cards IS 'PayMob card tokens for saved cards (no actual card data stored)';

COMMENT ON COLUMN public.saved_cards.card_token IS 'PayMob card token - NEVER store actual card numbers';
COMMENT ON COLUMN public.saved_cards.last_four_digits IS 'Last 4 digits of card for display purposes only';
