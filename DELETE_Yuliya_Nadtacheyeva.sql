-- TASKS Elearn module 4
-- Applying the DELETE and TRUNCATE Statement

-- 1. Remove a previously inserted film from the inventory and all corresponding rental records
-- 2. Remove any records related to you (as a customer) from all tables except "Customer" and "Inventory"


-- 1. Remove a previously inserted film from the inventory and all corresponding rental records

-- Remove corresponding rental records
DELETE FROM rental
WHERE inventory_id IN (
    SELECT inventory_id
    FROM inventory
    WHERE film_id = (SELECT film_id FROM film WHERE title = 'Manchester by the Sea')
);

-- Remove the film from the inventory
DELETE FROM inventory
WHERE film_id = (SELECT film_id FROM film WHERE title = 'Manchester by the Sea');

-- Remove related records from the film_actor table (if needed)
DELETE FROM film_actor
WHERE film_id = (SELECT film_id FROM film WHERE title = 'Manchester by the Sea');

-- Remove the film from the film table (if needed)
DELETE FROM film
WHERE title = 'Manchester by the Sea';

-- Verify the deletion
SELECT *
FROM inventory
WHERE film_id = (SELECT film_id FROM film WHERE title = 'Manchester by the Sea');

SELECT *
FROM rental
WHERE inventory_id IN (
    SELECT inventory_id
    FROM inventory
    WHERE film_id = (SELECT film_id FROM film WHERE title = 'Manchester by the Sea')
);

SELECT *
FROM film_actor
WHERE film_id = (SELECT film_id FROM film WHERE title = 'Manchester by the Sea');

SELECT *
FROM film
WHERE title = 'Manchester by the Sea';


-- 2. Remove any records related to you (as a customer) from all tables except "Customer" and "Inventory"

DELETE FROM payment
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Yuliya' AND last_name = 'Nadtacheyeva');

DELETE FROM rental
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Yuliya' AND last_name = 'Nadtacheyeva');