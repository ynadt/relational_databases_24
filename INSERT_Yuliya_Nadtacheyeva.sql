-- TASKS Elearn module 4
-- Applying the INSERT Statement

-- Choose one of your favorite films and add it to the "film" table. Fill in rental rates with 4.99 and rental durations with 2 weeks.
-- Add the actors who play leading roles in your favorite film to the "actor" and "film_actor" tables (three or more actors in total).
-- Add your favorite movies to any store's inventory.

-- Insert the film "Manchester by the Sea" if it doesn't already exist
INSERT INTO film (
    title,
    description,
    release_year,
    language_id,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    rating,
    special_features,
    fulltext
)
SELECT
    'Manchester by the Sea',
    'A man returns to his hometown to care for his nephew after his brother dies.',
    2016,
    (SELECT language_id FROM language WHERE name = 'English'),
    14,               -- Rental duration in days (2 weeks)
    4.99,             -- Rental rate
    137,              -- Length of the film in minutes
    19.99,            -- Replacement cost
    'R',              -- Rating of the film
    ARRAY['Deleted Scenes', 'Behind the Scenes'], -- Special features
    to_tsvector('Manchester by the Sea ' || 'A man returns to his hometown to care for his nephew after his brother dies.') -- Fulltext
WHERE NOT EXISTS (
    SELECT 1
    FROM film
    WHERE title = 'Manchester by the Sea'
);

-- Add actors using LEFT JOIN to avoid duplicates
INSERT INTO actor (first_name, last_name)
SELECT 'Casey', 'Affleck'
WHERE NOT EXISTS (
    SELECT 1
    FROM actor
    WHERE first_name = 'Casey' AND last_name = 'Affleck'
);

INSERT INTO actor (first_name, last_name)
SELECT 'Michelle', 'Williams'
WHERE NOT EXISTS (
    SELECT 1
    FROM actor
    WHERE first_name = 'Michelle' AND last_name = 'Williams'
);

INSERT INTO actor (first_name, last_name)
SELECT 'Kyle', 'Chandler'
WHERE NOT EXISTS (
    SELECT 1
    FROM actor
    WHERE first_name = 'Kyle' AND last_name = 'Chandler'
);


WITH film_id_cte AS (
    SELECT film_id
    FROM film
    WHERE title = 'Manchester by the Sea'
),
     actor_ids_cte AS (
         SELECT actor_id, first_name, last_name
         FROM actor
         WHERE (first_name, last_name) IN (('Casey', 'Affleck'), ('Michelle', 'Williams'), ('Kyle', 'Chandler'))
     )

INSERT INTO film_actor (actor_id, film_id)
SELECT
    a.actor_id,
    f.film_id
FROM actor_ids_cte a, film_id_cte f
WHERE NOT EXISTS (
    SELECT 1
    FROM film_actor
    WHERE actor_id = a.actor_id
      AND film_id = f.film_id
);

-- Insert the film into the store's inventory
INSERT INTO inventory (film_id, store_id, last_update)
SELECT
    (SELECT film_id FROM film WHERE title = 'Manchester by the Sea'),
    (SELECT store_id FROM store LIMIT 1),
    NOW()
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory
    WHERE film_id = (SELECT film_id FROM film WHERE title = 'Manchester by the Sea')
      AND store_id = (SELECT store_id FROM store LIMIT 1)
);


-- Check
SELECT *
FROM film
WHERE title = 'Manchester by the Sea';

SELECT *
FROM actor
WHERE (first_name = 'Casey' AND last_name = 'Affleck')
   OR (first_name = 'Michelle' AND last_name = 'Williams')
   OR (first_name = 'Kyle' AND last_name = 'Chandler');

-- check the film_actor table
SELECT a.first_name, a.last_name, fa.film_id
FROM film_actor fa
         JOIN actor a ON fa.actor_id = a.actor_id
WHERE fa.film_id = (SELECT film_id FROM film WHERE title = 'Manchester by the Sea');

-- Check if the film "Manchester by the Sea" is in the inventory of the first store
SELECT *
FROM inventory
WHERE film_id = (SELECT film_id FROM film WHERE title = 'Manchester by the Sea')
  AND store_id = (SELECT store_id FROM store LIMIT 1);
