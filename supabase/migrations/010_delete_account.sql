-- 010_delete_account.sql
-- Secure Account Deletion RPC

-- 1. Ensure deleted_users table exists with ALL required fields
create table if not exists public.deleted_users (
    id uuid not null primary key,
    auth_user_id uuid,
    name text,
    email text,
    phone text,
    country text,
    city text,
    area_id uuid,
    is_banned boolean,
    deletion_reason text,
    deleted_at timestamp with time zone default now(),
    original_created_at timestamp with time zone
);

-- 2. Create RPC function to handle deletion securely
-- Drop potentially conflicting functions to resolve PGRST203 (Ambiguous Reference)
drop function if exists public.delete_user_account();
drop function if exists public.delete_user_account(text);

-- Added optional 'reason' parameter
create or replace function public.delete_user_account(reason text default null)
returns void
language plpgsql
security definer
as $$
declare
    current_auth_id uuid;
    current_user_id uuid;
begin
    -- Get current Auth ID
    current_auth_id := auth.uid();

    -- Ensure user is logged in
    if current_auth_id is null then
        raise exception 'Not authorized';
    end if;

    -- Get Public User ID
    select id into current_user_id
    from public.users
    where auth_user_id = current_auth_id;

    if current_user_id is null then
        raise exception 'User not found';
    end if;

    -- 1. Archive user data to deleted_users with ALL fields
    insert into public.deleted_users (
        id, 
        auth_user_id, 
        name, 
        email, 
        phone, 
        country, 
        city, 
        area_id, 
        is_banned, 
        deletion_reason, 
        original_created_at
    )
    select 
        id, 
        auth_user_id, 
        name, 
        email, 
        phone, 
        country, 
        city, 
        area_id, 
        is_banned, 
        reason,
        created_at
    from public.users
    where id = current_user_id;

    -- 2. Delete Dependencies (Manual Cascade with Existence Checks)
    
    -- Addresses
    if to_regclass('public.user_addresses') is not null then
        execute 'delete from public.user_addresses where user_id = $1' using current_user_id;
    end if;
    
    -- Order Ratings
    if to_regclass('public.order_ratings') is not null then
        execute 'delete from public.order_ratings where user_id = $1' using current_user_id;
    end if;
    
    -- Orders
    if to_regclass('public.orders') is not null then
        execute 'delete from public.orders where user_id = $1' using current_user_id;
    end if;

    -- 3. Delete Dependencies (Auth User ID references)
    
    -- Favorites
    if to_regclass('public.favorites') is not null then
        execute 'delete from public.favorites where user_id = $1' using current_auth_id;
    end if;
    
    -- Wallets & Saved Cards
    if to_regclass('public.wallets') is not null then
        -- Transaction cleanup needed if wallet exists
        if to_regclass('public.wallet_transactions') is not null then
             execute 'delete from public.wallet_transactions where wallet_id in (select id from public.wallets where user_id = $1)' using current_auth_id;
        end if;
        execute 'delete from public.wallets where user_id = $1' using current_auth_id;
    end if;

    if to_regclass('public.saved_cards') is not null then
        execute 'delete from public.saved_cards where user_id = $1' using current_auth_id;
    end if;

    -- 4. Delete from public.users
    delete from public.users
    where id = current_user_id;

    -- User is now deleted from App Logic. 
    -- Auth User remains until Admin cleanup or Trigger.
end;
$$;
