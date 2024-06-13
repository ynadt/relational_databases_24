-- 1. Write a query that will return for each year the most popular in rental film among films released in one year.

-- TIRES: the query returns all films that are tied for the most popular in rental for that year
-- If we need only 1 film for year - we can use ROW_NUMBER() instead of RANK() in the subquery
SELECT
    release_year,
    title AS most_popular_film,
    rental_count
FROM (
         SELECT
             f.release_year,
             f.title,
             COUNT(r.rental_id) AS rental_count,
             RANK() OVER (PARTITION BY f.release_year ORDER BY COUNT(r.rental_id) DESC) AS rank
         FROM
             film f
                 JOIN inventory i ON f.film_id = i.film_id
                 JOIN rental r ON i.inventory_id = r.inventory_id
         GROUP BY
             f.release_year, f.title
     ) AS ranked_films
WHERE
    rank = 1
ORDER BY
    release_year;




-- 2. Write a query that will return the Top-5 actors who have appeared in Comedies more than anyone else.


-- Tires are not handled (it returns exactly 5 actors)
WITH comedy_actors AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        COUNT(fa.film_id) AS comedy_appearances
    FROM
        actor a
            JOIN film_actor fa ON a.actor_id = fa.actor_id
            JOIN film f ON fa.film_id = f.film_id
            JOIN film_category fc ON f.film_id = fc.film_id
            JOIN category c ON fc.category_id = c.category_id
    WHERE
        c.name = 'Comedy'
    GROUP BY
        a.actor_id, a.first_name, a.last_name
)
SELECT
    ca.first_name,
    ca.last_name,
    ca.comedy_appearances
FROM
    comedy_actors ca
ORDER BY
    ca.comedy_appearances DESC
LIMIT 5;


-- option with tires:
WITH comedy_actors AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        COUNT(fa.film_id) AS comedy_appearances
    FROM
        actor a
            JOIN film_actor fa ON a.actor_id = fa.actor_id
            JOIN film f ON fa.film_id = f.film_id
            JOIN film_category fc ON f.film_id = fc.film_id
            JOIN category c ON fc.category_id = c.category_id
    WHERE
        c.name = 'Comedy'
    GROUP BY
        a.actor_id, a.first_name, a.last_name
),
     ranked_comedy_actors AS (
         SELECT
             ca.actor_id,
             ca.first_name,
             ca.last_name,
             ca.comedy_appearances,
             DENSE_RANK() OVER (ORDER BY ca.comedy_appearances DESC) AS rank
         FROM
             comedy_actors ca
     )
SELECT
    rca.first_name,
    rca.last_name,
    rca.comedy_appearances
FROM
    ranked_comedy_actors rca
WHERE
    rca.rank <= 5
ORDER BY
    rca.comedy_appearances DESC;




-- 3. Write a query that will return the names of actors who have not starred in “Action” films.

SELECT a.first_name, a.last_name
FROM actor a
WHERE a.actor_id NOT IN (
    SELECT fa.actor_id
    FROM film_actor fa
             JOIN film f ON fa.film_id = f.film_id
             JOIN film_category fc ON f.film_id = fc.film_id
             JOIN category c ON fc.category_id = c.category_id
    WHERE c.name = 'Action'
)
ORDER BY a.first_name, a.last_name;




-- 4. Write a query that will return the three most popular in rental films by each genre.
--Option with tires
SELECT
    genre,
    title AS most_popular_film,
    rental_count
FROM (
         SELECT
             c.name AS genre,
             f.title,
             COUNT(r.rental_id) AS rental_count,
             DENSE_RANK() OVER (PARTITION BY c.name ORDER BY COUNT(r.rental_id) DESC) AS rank
         FROM
             film f
                 JOIN inventory i ON f.film_id = i.film_id
                 JOIN rental r ON i.inventory_id = r.inventory_id
                 JOIN film_category fc ON f.film_id = fc.film_id
                 JOIN category c ON fc.category_id = c.category_id
         GROUP BY
             c.name, f.film_id, f.title
     ) AS ranked_films
WHERE
    rank <= 3
ORDER BY
    genre,
    rental_count DESC;



-- Option without tires
SELECT
    genre,
    title AS most_popular_film,
    rental_count
FROM (
         SELECT
             c.name AS genre,
             f.title,
             COUNT(r.rental_id) AS rental_count,
             ROW_NUMBER() OVER (PARTITION BY c.name ORDER BY COUNT(r.rental_id) DESC) AS row_num
         FROM
             film f
                 JOIN inventory i ON f.film_id = i.film_id
                 JOIN rental r ON i.inventory_id = r.inventory_id
                 JOIN film_category fc ON f.film_id = fc.film_id
                 JOIN category c ON fc.category_id = c.category_id
         GROUP BY
             c.name, f.title, f.film_id
     ) AS ranked_films
WHERE
    row_num <= 3
ORDER BY
    genre,
    rental_count DESC;





-- 5. Calculate the number of films released each year and cumulative total by the number of films.
-- Write two query versions, one with window functions, the other without.

-- With window functions

SELECT
    release_year,
    COUNT(*) AS films_released,
    SUM(COUNT(*)) OVER (ORDER BY release_year) AS cumulative_total
FROM
    film
GROUP BY
    release_year
ORDER BY
    release_year;


-- Without Using Window Functions
WITH yearly_films AS (
    SELECT
        release_year,
        COUNT(*) AS films_released
    FROM
        film
    GROUP BY
        release_year
)
SELECT
    yf1.release_year,
    yf1.films_released,
    (SELECT SUM(yf2.films_released)
     FROM yearly_films yf2
     WHERE yf2.release_year <= yf1.release_year) AS cumulative_total
FROM
    yearly_films yf1
ORDER BY
    yf1.release_year;





-- 6. Calculate a monthly statistics based on “rental_date” field from “Rental” table that for each month
-- will show the percentage of “Animation” films from the total number of rentals.
-- Write two query versions, one with window functions, the other without.

-- With window functions
WITH monthly_rentals AS (
    SELECT
        DATE_TRUNC('month', r.rental_date) AS rental_month,
        COUNT(*) AS total_rentals,
        SUM(CASE WHEN c.name = 'Animation' THEN 1 ELSE 0 END) AS animation_rentals
    FROM
        rental r
            JOIN inventory i ON r.inventory_id = i.inventory_id
            JOIN film f ON i.film_id = f.film_id
            JOIN film_category fc ON f.film_id = fc.film_id
            JOIN category c ON fc.category_id = c.category_id
    GROUP BY
        rental_month
)
SELECT
    TO_CHAR(rental_month, 'YYYY-MM') AS month,
    animation_rentals,
    total_rentals,
    ROUND((animation_rentals::decimal / total_rentals * 100), 2) AS percentage_animation_rentals
FROM
    monthly_rentals
ORDER BY
    rental_month;

-- Without Window Functions
WITH monthly_totals AS (
    SELECT
        DATE_TRUNC('month', r.rental_date) AS rental_month,
        COUNT(*) AS total_rentals
    FROM
        rental r
    GROUP BY
        rental_month
),
     animation_totals AS (
         SELECT
             DATE_TRUNC('month', r.rental_date) AS rental_month,
             COUNT(*) AS animation_rentals
         FROM
             rental r
                 JOIN inventory i ON r.inventory_id = i.inventory_id
                 JOIN film f ON i.film_id = f.film_id
                 JOIN film_category fc ON f.film_id = fc.film_id
                 JOIN category c ON fc.category_id = c.category_id
         WHERE
             c.name = 'Animation'
         GROUP BY
             rental_month
     )
SELECT
    TO_CHAR(mt.rental_month, 'YYYY-MM') AS month,
    COALESCE(at.animation_rentals, 0) AS animation_rentals,
    mt.total_rentals,
    ROUND((COALESCE(at.animation_rentals, 0)::decimal / mt.total_rentals * 100), 2) AS percentage_animation_rentals
FROM
    monthly_totals mt
        LEFT JOIN animation_totals at ON mt.rental_month = at.rental_month
ORDER BY
    mt.rental_month;






-- 7. Write a query that will return the names of actors who have starred in “Action” films more than in
-- “Drama” film.

WITH actor_genre_counts AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        SUM(CASE WHEN c.name = 'Action' THEN 1 ELSE 0 END) AS action_count,
        SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END) AS drama_count
    FROM
        actor a
            JOIN film_actor fa ON a.actor_id = fa.actor_id
            JOIN film f ON fa.film_id = f.film_id
            JOIN film_category fc ON f.film_id = fc.film_id
            JOIN category c ON fc.category_id = c.category_id
    GROUP BY
        a.actor_id, a.first_name, a.last_name
)
SELECT
    agc.first_name,
    agc.last_name
FROM
    actor_genre_counts agc
WHERE
    agc.action_count > agc.drama_count
ORDER BY
    agc.first_name, agc.last_name;





-- 8. Write a query that will return the top-5 customers who spent the most money watching Comedies.

--without tires
WITH comedy_rentals AS (
    SELECT
        r.customer_id,
        p.amount
    FROM
        rental r
            JOIN payment p ON r.rental_id = p.rental_id
            JOIN inventory i ON r.inventory_id = i.inventory_id
            JOIN film f ON i.film_id = f.film_id
            JOIN film_category fc ON f.film_id = fc.film_id
            JOIN category c ON fc.category_id = c.category_id
    WHERE
        c.name = 'Comedy'
),
     customer_spending AS (
         SELECT
             cr.customer_id,
             SUM(cr.amount) AS total_spent
         FROM
             comedy_rentals cr
         GROUP BY
             cr.customer_id
     )
SELECT
    c.first_name,
    c.last_name,
    cs.total_spent
FROM
    customer_spending cs
        JOIN customer c ON cs.customer_id = c.customer_id
ORDER BY
    cs.total_spent DESC
LIMIT 5;


-- with handling tires
WITH ranked_customers AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(p.amount) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(p.amount) DESC) AS rank
    FROM
        customer c
            JOIN rental r ON c.customer_id = r.customer_id
            JOIN payment p ON r.rental_id = p.rental_id
            JOIN inventory i ON r.inventory_id = i.inventory_id
            JOIN film f ON i.film_id = f.film_id
            JOIN film_category fc ON f.film_id = fc.film_id
            JOIN category cat ON fc.category_id = cat.category_id
    WHERE
        cat.name = 'Comedy'
    GROUP BY
        c.customer_id, c.first_name, c.last_name
)
SELECT
    first_name,
    last_name,
    total_spent
FROM
    ranked_customers
WHERE
    rank <= 5
ORDER BY
    rank, last_name, first_name;




-- 9.  In the “Address” table, in the “address” field, the last word indicates the "type" of a street: Street,
-- Lane, Way, etc. Write a query that will return all "types" of streets and the number of addresses
-- related to this "type".

SELECT
    split_part(address, ' ', array_length(string_to_array(address, ' '), 1)) AS street_type,
    COUNT(*) AS address_count
FROM
    address
GROUP BY
    street_type
ORDER BY
    address_count DESC;




-- 10. Write a query that will return a list of movie ratings, indicate for each rating the total number of
-- films with this rating, the top-3 categories by the number of films in this category and the number of
-- film in this category with this rating.

WITH category_counts AS (
    SELECT
        f.rating,
        c.name AS category,
        COUNT(*) AS category_count
    FROM
        film f
            JOIN film_category fc ON f.film_id = fc.film_id
            JOIN category c ON fc.category_id = c.category_id
    GROUP BY
        f.rating, c.name
),
     ranked_categories AS (
         SELECT
             rating,
             category,
             category_count,
             ROW_NUMBER() OVER (PARTITION BY rating ORDER BY category_count DESC) AS rank
         FROM
             category_counts
     )
SELECT
    f.rating,
    COUNT(*) AS total,
    MAX(CASE WHEN rc.rank = 1 THEN rc.category || ': ' || rc.category_count::text END) AS category1,
    MAX(CASE WHEN rc.rank = 2 THEN rc.category || ': ' || rc.category_count::text END) AS category2,
    MAX(CASE WHEN rc.rank = 3 THEN rc.category || ': ' || rc.category_count::text END) AS category3
FROM
    film f
        LEFT JOIN ranked_categories rc ON f.rating = rc.rating
GROUP BY
    f.rating
ORDER BY
    total DESC;

