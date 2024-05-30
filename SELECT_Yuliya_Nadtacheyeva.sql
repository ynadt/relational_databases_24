-- TASKS Elearn module 4

-- TASK 1:
-- Which staff members made the highest revenue for each store and deserve a bonus for the year 2017?


-- TASK 1 Option 1
-- In case multiple staff members have the same highest revenue, they all are included.

-- Using CTEs
WITH staff_revenue AS (
    SELECT
        st.store_id,
        s.staff_id,
        SUM(p.amount) AS total_revenue
    FROM
        store st
            JOIN staff s ON st.store_id = s.store_id
            JOIN rental r ON s.staff_id = r.staff_id
            JOIN payment p ON r.rental_id = p.rental_id
    WHERE
        EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY
        st.store_id, s.staff_id
),
     max_revenue_per_store AS (
         SELECT
             store_id,
             MAX(total_revenue) AS max_revenue
         FROM
             staff_revenue
         GROUP BY
             store_id
     )
SELECT
    sr.store_id,
    sr.staff_id,
    sr.total_revenue
FROM
    staff_revenue sr
        JOIN max_revenue_per_store mrps ON sr.store_id = mrps.store_id AND sr.total_revenue = mrps.max_revenue
ORDER BY
    sr.store_id,
    sr.staff_id;



-- TASK 1 Option 2
-- Using subqueries directly in the FROM clause without CTEs
SELECT
    sr.store_id,
    sr.staff_id,
    sr.total_revenue
FROM (
         SELECT
             st.store_id,
             s.staff_id,
             SUM(p.amount) AS total_revenue
         FROM
             store st
                 JOIN staff s ON st.store_id = s.store_id
                 JOIN rental r ON s.staff_id = r.staff_id
                 JOIN payment p ON r.rental_id = p.rental_id
         WHERE
             EXTRACT(YEAR FROM p.payment_date) = 2017
         GROUP BY
             st.store_id, s.staff_id
     ) sr
         JOIN (
    SELECT
        store_id,
        MAX(total_revenue) AS max_revenue
    FROM (
             SELECT
                 st.store_id,
                 SUM(p.amount) AS total_revenue
             FROM
                 store st
                     JOIN staff s ON st.store_id = s.store_id
                     JOIN rental r ON s.staff_id = r.staff_id
                     JOIN payment p ON r.rental_id = p.rental_id
             WHERE
                 EXTRACT(YEAR FROM p.payment_date) = 2017
             GROUP BY
                 st.store_id, s.staff_id
         ) temp
    GROUP BY store_id
) mrps ON sr.store_id = mrps.store_id AND sr.total_revenue = mrps.max_revenue
ORDER BY sr.store_id, sr.staff_id;


-- TASK 1 Option 3
-- using the RANK() function

WITH staff_revenue AS (
    SELECT
        st.store_id,
        s.staff_id,
        SUM(p.amount) AS total_revenue,
        RANK() OVER (PARTITION BY st.store_id ORDER BY SUM(p.amount) DESC) AS revenue_rank
    FROM
        store st
            JOIN staff s ON st.store_id = s.store_id
            JOIN rental r ON s.staff_id = r.staff_id
            JOIN payment p ON r.rental_id = p.rental_id
    WHERE
        EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY
        st.store_id, s.staff_id
)
SELECT
    store_id,
    staff_id,
    total_revenue
FROM
    staff_revenue
WHERE
    revenue_rank = 1
ORDER BY
    store_id,
    staff_id;


-- TASK 2
-- Which five movies were rented more than the others, and what is the expected age of the audience for these movies?

-- TASK 2 Option 1
-- If we need exactly 5 movies and don't care about the ties in the number of rentals:

WITH movie_rentals AS (
    SELECT
        f.film_id,
        f.title,
        f.rating,
        COUNT(r.rental_id) AS rental_count
    FROM
        film f
            JOIN inventory i ON f.film_id = i.film_id
            JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY
        f.film_id, f.title, f.rating
    ORDER BY
        rental_count DESC
    LIMIT 5
)
SELECT
    mr.title,
    mr.rental_count,
    CASE
        WHEN mr.rating = 'G' THEN 10
        WHEN mr.rating = 'PG' THEN 13
        WHEN mr.rating = 'PG-13' THEN 15
        WHEN mr.rating = 'R' THEN 18
        WHEN mr.rating = 'NC-17' THEN 21
        END AS expected_age
FROM
    movie_rentals mr
ORDER BY
    mr.rental_count DESC;



-- TASK 2 Option 2 (with ties - if there are multiple movies with the same rental count it shows all of them)
WITH movie_rentals AS (
    SELECT
        f.film_id,
        f.title,
        f.rating,
        COUNT(r.rental_id) AS rental_count,
        DENSE_RANK() OVER (ORDER BY COUNT(r.rental_id) DESC) AS rental_rank,
        CASE
            WHEN f.rating = 'G' THEN 10
            WHEN f.rating = 'PG' THEN 13
            WHEN f.rating = 'PG-13' THEN 15
            WHEN f.rating = 'R' THEN 18
            WHEN f.rating = 'NC-17' THEN 21
            END AS expected_age
    FROM
        film f
            JOIN inventory i ON f.film_id = i.film_id
            JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY
        f.film_id, f.title, f.rating
)
SELECT
    mr.title,
    mr.rental_count,
    mr.expected_age
FROM
    movie_rentals mr
WHERE
    mr.rental_rank <= 5
ORDER BY
    mr.rental_count DESC;


-- TASK 2 Option 3 (with ties)

WITH movie_rentals AS (
    SELECT
        f.film_id,
        f.title,
        f.rating,
        COUNT(r.rental_id) AS rental_count,
        DENSE_RANK() OVER (ORDER BY COUNT(r.rental_id) DESC) AS rental_rank
    FROM
        film f
            JOIN inventory i ON f.film_id = i.film_id
            JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY
        f.film_id, f.title, f.rating
)
SELECT
    mr.title,
    mr.rental_count,
    CASE
        WHEN mr.rating = 'G' THEN 10
        WHEN mr.rating = 'PG' THEN 13
        WHEN mr.rating = 'PG-13' THEN 15
        WHEN mr.rating = 'R' THEN 18
        WHEN mr.rating = 'NC-17' THEN 21
        END AS expected_age
FROM
    movie_rentals mr
WHERE
    mr.rental_rank <= 5
ORDER BY
    mr.rental_count DESC;



-- TASK 3
-- Which actors/actresses didn't act for a longer period of time than the others?

-- TASK 3 Option 1

WITH actor_inactivity_period AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, TO_DATE(MAX(f.release_year)::text, 'YYYY'))) AS inactivity_period
    FROM
        actor a
            JOIN film_actor fa ON a.actor_id = fa.actor_id
            JOIN film f ON fa.film_id = f.film_id
    GROUP BY
        a.actor_id, a.first_name, a.last_name
)
SELECT
    ai.actor_id,
    ai.first_name,
    ai.last_name,
    ai.inactivity_period
FROM
    actor_inactivity_period ai
WHERE
    ai.inactivity_period = (
        SELECT MAX(inactivity_period)
        FROM actor_inactivity_period
    )
ORDER BY
    ai.actor_id;


-- TASK 3 Option 2

WITH actor_last_film AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        MAX(f.release_year) AS last_film_year
    FROM
        actor a
            JOIN film_actor fa ON a.actor_id = fa.actor_id
            JOIN film f ON fa.film_id = f.film_id
    GROUP BY
        a.actor_id, a.first_name, a.last_name
),
     actor_inactivity_period AS (
         SELECT
             al.actor_id,
             al.first_name,
             al.last_name,
             EXTRACT(YEAR FROM AGE(CURRENT_DATE, TO_DATE(al.last_film_year::text, 'YYYY'))) AS inactivity_period
         FROM
             actor_last_film al
     )
SELECT
    ai.actor_id,
    ai.first_name,
    ai.last_name,
    ai.inactivity_period
FROM
    actor_inactivity_period ai
WHERE
    ai.inactivity_period = (
        SELECT MAX(inactivity_period)
        FROM actor_inactivity_period
    )
ORDER BY
    ai.actor_id;