-- TASKS Elearn module 4
-- Applying the UPDATE Statement

-- 1. Alter the rental duration and rental rates of the film you inserted before to three weeks and 9.99, respectively.
-- 2. Alter any existing customer in the database with at least 10 rental and 10 payment records. Change their personal data to yours (first name, last name, address, etc.). You can use any existing address from the "address" table. Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.
-- 3. Change the customer's create_date value to current_date.


-- 1. Alter the rental duration and rental rates of the film you inserted before to three weeks and 9.99, respectively.

UPDATE film
SET rental_duration = 21, -- 3 weeks
    rental_rate = 9.99
WHERE title = 'Manchester by the Sea';

-- Verify the updates
SELECT title, rental_duration, rental_rate
FROM film
WHERE title = 'Manchester by the Sea';

-- 2. Alter any existing customer in the database with at least 10 rental and 10 payment records.
-- Change their personal data to yours (first name, last name, address, etc.).
-- You can use any existing address from the "address" table. Please do not perform any updates on the "address" table, as this can impact multiple records with the same address.

-- Identify a customer and update
WITH suitable_customer AS (
    SELECT c.customer_id
    FROM customer c
             JOIN rental r ON c.customer_id = r.customer_id
             JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY c.customer_id
    HAVING COUNT(r.rental_id) >= 10 AND COUNT(p.payment_id) >= 10
    LIMIT 1
),
     existing_address AS (
         SELECT address_id
         FROM address
         LIMIT 1
     )
UPDATE customer
SET first_name = 'Yuliya',
    last_name = 'Nadtacheyeva',
    address_id = (SELECT address_id FROM existing_address)
WHERE customer_id = (SELECT customer_id FROM suitable_customer);


-- 3. Change the customer's create_date value to current_date.

UPDATE customer
SET create_date = current_date
WHERE first_name = 'Yuliya' AND last_name = 'Nadtacheyeva';

-- Verify the update
SELECT customer_id, first_name, last_name, create_date
FROM customer
WHERE first_name = 'Yuliya' AND last_name = 'Nadtacheyeva';
