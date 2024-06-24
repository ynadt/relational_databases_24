-- 1. Create a new user with the username "rentaluser" and the password "rentalpassword".
-- Give the user the ability to connect to the database but no other permissions.


-- Check if the role "rentaluser" exists
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rentaluser') THEN
            -- we can also use:
            -- CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
            CREATE ROLE rentaluser WITH LOGIN PASSWORD 'rentalpassword';
        ELSE
            RAISE NOTICE 'Role "rentaluser" already exists, skipping creation.';
        END IF;
    END
$$;

-- Grant the user the ability to connect to the database "dvdrental".
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;



-- 2.Grant "rentaluser" SELECT permission for the "customer" table.
-- Сheck to make sure this permission works correctly—write a SQL query to select all customers.

GRANT SELECT ON TABLE customer TO rentaluser;

SET ROLE rentaluser;

SELECT *
FROM customer;

-- Reset the role back to the original
RESET ROLE;




-- 3. Create a new user group called "rental" and add "rentaluser" to the group.

-- Create the "rental" role if it does not exist
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rental') THEN
            CREATE ROLE rental NOLOGIN;
        END IF;
    END
$$;

-- Add "rentaluser" to the "rental" role if not already a member
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_auth_members
                       WHERE roleid = (SELECT oid FROM pg_roles WHERE rolname = 'rental')
                         AND member = (SELECT oid FROM pg_roles WHERE rolname = 'rentaluser')) THEN
            GRANT rental TO rentaluser;
        END IF;
    END
$$;
--



-- 4. Grant the "rental" group INSERT and UPDATE permissions for the "rental" table.
-- Insert a new row and update one existing row in the "rental" table under that role.

GRANT INSERT, UPDATE ON TABLE rental TO rental;
GRANT USAGE ON SEQUENCE rental_rental_id_seq TO rental; -- to avoid error: permission denied for sequence rental_rental_id_seq when we insert
GRANT SELECT ON TABLE rental TO rental; -- to avoid error: permission denied for table rental when we select (can be skipped if we don't need to check for existence))

SET ROLE rentaluser;

-- If in this task we are supposed to use rental role and not rentaluser role, we need first to alter the rental role to allow login:
-- ALTER ROLE rental WITH LOGIN PASSWORD 'rentalpassword';
-- SET ROLE rental;

-- Insert new row
DO
$$
    BEGIN
        -- Attempt to insert the new record
        INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
        VALUES ('2024-06-15', 1, 1, '2024-06-16', 1)
        ON CONFLICT (rental_date, inventory_id, customer_id) DO NOTHING;

        -- Check if the record was inserted
        IF NOT FOUND THEN
            RAISE NOTICE 'Record with rental_date %, inventory_id %, customer_id % already exists.',
                '2024-06-15', 1, 1;
        END IF;
    END
$$;


-- Update an existing row in the rental table (with existence check)
DO
$$
    BEGIN
        IF EXISTS (SELECT 1 FROM rental WHERE rental_id = 1) THEN
            UPDATE rental SET return_date = '2024-06-17' WHERE rental_id = 1;
        ELSE
            RAISE NOTICE 'Rental with rental_id 1 does not exist.';
        END IF;
    END
$$;

-- Reset the role back
RESET ROLE;




--5 Revoke the "rental" group's INSERT permission for the "rental" table.
-- Try to insert new rows into the "rental" table make sure this action is denied.

REVOKE INSERT ON TABLE rental FROM rental;


SET ROLE rental;

DO
$$
    BEGIN
        -- Attempt to insert the new record
        INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
        VALUES ('2024-06-15', 1, 1, '2024-06-16', 1)
        ON CONFLICT (rental_date, inventory_id, customer_id) DO NOTHING;

        -- Check if the record was inserted
        IF NOT FOUND THEN
            RAISE NOTICE 'Record with rental_date %, inventory_id %, customer_id % already exists.',
                '2024-06-15', 1, 1;
        END IF;
    END
$$;

RESET ROLE;




--6. Create a personalized role for any customer already existing in the dvd_rental database.
-- The name of the role name must be client_{first_name}_{last_name} (omit curly brackets).
-- The customer's payment and rental history must not be empty.
-- Configure that role so that the customer can only access their own data in the "rental" and "payment" tables.
-- Write a query to make sure this user sees only their own data.

-- Step 1: Find a customer with non-empty rental and payment history
-- In my case it's customer_id = 1 (MARY SMITH)
SELECT c.customer_id, c.first_name, c.last_name
FROM customer c
WHERE EXISTS (
    SELECT 1
    FROM rental r
    WHERE r.customer_id = c.customer_id
)
  AND EXISTS (
    SELECT 1
    FROM payment p
    WHERE p.customer_id = c.customer_id
)
ORDER BY c.customer_id
LIMIT 1;


-- Step 2: Create the role if it doesn't exist for the customer MARY SMITH (customer_id = 1)
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'client_mary_smith') THEN
            CREATE ROLE client_mary_smith WITH LOGIN PASSWORD 'password';
        ELSE
            RAISE NOTICE 'Role "client_mary_smith" already exists, skipping creation.';
        END IF;
    END
$$;

-- Step 3: Grant SELECT permissions on the tables
GRANT SELECT ON TABLE rental TO client_mary_smith;
GRANT SELECT ON TABLE payment TO client_mary_smith;

-- Step 4: Enable RLS and create policies
-- Enable RLS on the rental table
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists to avoid errors
DROP POLICY IF EXISTS client_rental_policy ON rental;

-- Create RLS policy for the rental table
CREATE POLICY client_rental_policy ON rental
    FOR SELECT
    USING (customer_id = 1);

-- Enable RLS on the payment table
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists to avoid errors
DROP POLICY IF EXISTS client_payment_policy ON payment;

-- Create RLS policy for the payment table
CREATE POLICY client_payment_policy ON payment
    FOR SELECT
    USING (customer_id = 1);

-- Step 5: Test the role
SET ROLE client_mary_smith;

SELECT * FROM rental;
SELECT * FROM payment;

RESET ROLE;
