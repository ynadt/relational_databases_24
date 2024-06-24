-- 1 Create a view called "sales_revenue_by_category_qtr"
-- that shows the film category and total sales revenue for the current quarter.
-- The view should only display categories with at least one sale in the current quarter.
-- The current quarter should be determined dynamically.


CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT
    c.name AS category,
    SUM(p.amount) AS total_revenue
FROM
    payment p
        JOIN rental r ON p.rental_id = r.rental_id
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film_category fc ON i.film_id = fc.film_id
        JOIN category c ON fc.category_id = c.category_id
WHERE
    r.rental_date >= date_trunc('quarter', CURRENT_DATE)
GROUP BY
    c.name
HAVING
    COUNT(p.payment_id) > 0;  -- Ensure there is at least one sale in the current quarter


SELECT * FROM sales_revenue_by_category_qtr;


-- 2 Create a query language function called "get_sales_revenue_by_category_qtr" that accepts one parameter
-- representing the current quarter and returns the same result as the "sales_revenue_by_category_qtr" view.

CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(input_date DATE)
    RETURNS TABLE(category TEXT, total_revenue NUMERIC) AS $$
DECLARE
    current_quarter_start TIMESTAMPTZ;
BEGIN
    current_quarter_start := date_trunc('quarter', input_date)::timestamptz;

    RETURN QUERY
        SELECT
            c.name AS category,
            SUM(p.amount) AS total_revenue
        FROM
            payment p
                JOIN rental r ON p.rental_id = r.rental_id
                JOIN inventory i ON r.inventory_id = i.inventory_id
                JOIN film_category fc ON i.film_id = fc.film_id
                JOIN category c ON fc.category_id = c.category_id
        WHERE
            r.rental_date >= current_quarter_start
        GROUP BY
            c.name
        HAVING
            COUNT(p.payment_id) > 0;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_sales_revenue_by_category_qtr(CURRENT_DATE);

SELECT * FROM get_sales_revenue_by_category_qtr('2007-04-01');




-- 3 Create a procedure language function called "new_movie" that takes
-- a movie title as a parameter and inserts a new movie with the given title in the film table.
-- The function should generate a new unique film ID,
-- set the rental rate to 4.99,
-- the rental duration to three days,
-- the replacement cost to 19.99,
-- the release year to the current year, and
-- "language" as Klingon.
-- The function should also verify that the language exists in the "language" table.
-- Then, ensure that no such function has been created before; if so, replace it.


CREATE OR REPLACE FUNCTION new_movie(movie_title TEXT)
    RETURNS VOID AS $$
DECLARE
    lang_id INTEGER;
    current_year INTEGER := EXTRACT(YEAR FROM CURRENT_DATE);
    new_film_id INTEGER;
BEGIN
    -- Check if the movie already exists
    IF EXISTS (
        SELECT 1
        FROM film
        WHERE title = movie_title
    ) THEN
        RAISE NOTICE 'Movie already exists';
        RETURN;
    END IF;

    -- Check if the language 'Klingon' exists in the language table
    SELECT language_id INTO lang_id
    FROM language
    WHERE name = 'Klingon';

    -- If 'Klingon' does not exist, insert it
    IF NOT FOUND THEN
        INSERT INTO language (name)
        VALUES ('Klingon')
        RETURNING language_id INTO lang_id;
    END IF;

    -- Generate a new unique film ID
    -- In general, I am not sure that generating unique IDs within a function like this is a good idea
    -- the same is done in our database for film_id without this function, film_id defaults to nextval('film_film_id_seq')
    -- but I'll follow the instructions of a task as given
    SELECT NEXTVAL('film_film_id_seq') INTO new_film_id;
    -- If we are not allowed to use NEXTVAL('film_film_id_seq') we can generate a new unique film ID using current time and random number
    -- new_film_id := EXTRACT(EPOCH FROM NOW())::BIGINT * 100000 + (RANDOM() * 100000)::BIGINT;


    -- Insert the new movie into the film table with specified columns
    INSERT INTO film (
        film_id,
        title,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost,
        fulltext
    ) VALUES (
                 new_film_id,
                 movie_title,
                 current_year,
                 lang_id,
                 3,            -- Rental duration in days
                 4.99,         -- Rental rate
                 19.99,         -- Replacement cost
                 to_tsvector('english', movie_title)
             );
END;
$$ LANGUAGE plpgsql;


SELECT new_movie('New Movie to make a check');
SELECT * FROM film WHERE title = 'New Movie to make a check';




