-- TASKS Elearn module 3

-- TASK 1:
-- Which staff members made the highest revenue for each store and deserve a bonus for the year 2017?


-- TASK 1 Option 1
-- In case multiple staff members have the same highest revenue, they all are included.

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
WHERE sr.total_revenue = (
    SELECT
        MAX(sub.total_revenue)
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
         ) sub
    WHERE sub.store_id = sr.store_id
)
ORDER BY
    sr.store_id, sr.staff_id;


-- TASK 2
-- Which five movies were rented more than the others, and what is the expected age of the audience for these movies?

-- TASK 2 Option 1
WITH top_movies AS (
    SELECT
        f.film_id,
        f.title,
        COUNT(r.rental_id) AS rental_count
    FROM
        film f
            JOIN inventory i ON f.film_id = i.film_id
            JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY
        f.film_id, f.title
    ORDER BY
        rental_count DESC
    LIMIT 5
),
     customer_ages AS (
         SELECT
             c.customer_id,
             DATE_PART('year', AGE(c.create_date)) AS age
         FROM
             customer c
     )
SELECT
    tm.title,
    tm.rental_count,
    AVG(ca.age) AS expected_age
FROM
    top_movies tm
        JOIN inventory i ON tm.film_id = i.film_id
        JOIN rental r ON i.inventory_id = r.inventory_id
        JOIN customer c ON r.customer_id = c.customer_id
        JOIN customer_ages ca ON c.customer_id = ca.customer_id
GROUP BY
    tm.title, tm.rental_count
ORDER BY
    tm.rental_count DESC;

-- TASK 2 Option 2

WITH top_movies AS (
    SELECT
        f.film_id,
        f.title,
        COUNT(r.rental_id) AS rental_count
    FROM
        film f
            JOIN inventory i ON f.film_id = i.film_id
            JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY
        f.film_id, f.title
    ORDER BY
        rental_count DESC
    LIMIT 5
)
SELECT
    tm.title,
    tm.rental_count,
    AVG(DATE_PART('year', AGE(c.create_date))) AS expected_age
FROM
    top_movies tm
        JOIN inventory i ON tm.film_id = i.film_id
        JOIN rental r ON i.inventory_id = r.inventory_id
        JOIN customer c ON r.customer_id = c.customer_id
GROUP BY
    tm.title, tm.rental_count
ORDER BY
    tm.rental_count DESC;


-- TASK 2 Option 3 with ties (if there are multiple movies with the same rental count we show all of them)
WITH movie_rentals AS (
    SELECT
        f.film_id,
        f.title,
        COUNT(r.rental_id) AS rental_count,
        DENSE_RANK() OVER (ORDER BY COUNT(r.rental_id) DESC) AS rental_rank
    FROM
        film f
            JOIN inventory i ON f.film_id = i.film_id
            JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY
        f.film_id, f.title
),
     top_movies AS (
         SELECT
             film_id,
             title,
             rental_count
         FROM
             movie_rentals
         WHERE
             rental_rank <= 5
     ),
     customer_ages AS (
         SELECT
             c.customer_id,
             DATE_PART('year', AGE(c.create_date)) AS age
         FROM
             customer c
     )
SELECT
    tm.title,
    tm.rental_count,
    AVG(ca.age) AS expected_age
FROM
    top_movies tm
        JOIN inventory i ON tm.film_id = i.film_id
        JOIN rental r ON i.inventory_id = r.inventory_id
        JOIN customer c ON r.customer_id = c.customer_id
        JOIN customer_ages ca ON c.customer_id = ca.customer_id
GROUP BY
    tm.title, tm.rental_count
ORDER BY
    tm.rental_count DESC;


-- TASK 3
-- Which actors/actresses didn't act for a longer period of time than the others?

-- TASK 3 Option 1

-- If we need to find the single actor/actress with the longest period of inactivity
-- Plus if there are multiple actors/actresses with the same longest inactivity period, we return all of them

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
     ),
     max_inactivity_period AS (
         SELECT
             MAX(inactivity_period) AS max_period
         FROM
             actor_inactivity_period
     )
SELECT
    ai.actor_id,
    ai.first_name,
    ai.last_name,
    ai.inactivity_period
FROM
    actor_inactivity_period ai
        JOIN max_inactivity_period mip ON ai.inactivity_period = mip.max_period
ORDER BY
    ai.actor_id;

-- TASK 3 Option 2
-- The filtering is done using a subquery in the WHERE clause to find the maximum inactivity period

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

