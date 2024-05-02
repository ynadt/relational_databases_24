--TASK 1

CREATE TABLE Orders
(
    o_id       SERIAL PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE Products
(
    p_name TEXT PRIMARY KEY,
    price  MONEY NOT NULL
);

CREATE TABLE Order_Items
(
    order_id     INT           NOT NULL,
    product_name TEXT          NOT NULL,
    amount       NUMERIC(7, 2) NOT NULL DEFAULT 1 CHECK (amount > 0),
    PRIMARY KEY (order_id, product_name),
    FOREIGN KEY (order_id) REFERENCES Orders (o_id),
    FOREIGN KEY (product_name) REFERENCES Products (p_name)
);

--TASK 2

INSERT INTO Orders (order_date)
VALUES ('2024-04-01'),
       ('2024-04-02');

INSERT INTO Products (p_name, price)
VALUES ('p1', '15.00'),
       ('p2', '25.00');

INSERT INTO Order_Items (order_id, product_name)
VALUES (1, 'p1'),
       (1, 'p2');

INSERT INTO Order_Items (order_id, product_name, amount)
VALUES (2, 'p1', 2.5),
       (2, 'p2', 3);

--TASK 3

-- Add a new column 'p_id' to 'Products' table
ALTER TABLE Products
    ADD COLUMN IF NOT EXISTS p_id SERIAL;

-- Add a 'product_id' column to 'Order_Items'
ALTER TABLE Order_Items
    ADD COLUMN IF NOT EXISTS product_id INT;

-- Update the newly added 'product_id' in 'Order_Items' to match 'p_id' from 'Products' based on the existing 'product_name'
UPDATE Order_Items
SET product_id = (SELECT p_id FROM Products WHERE p_name = Order_Items.product_name);

-- Remove existing foreign key constraint that links 'product_name' in 'Order_Items' to 'p_name' in 'Products'
ALTER TABLE Order_Items
    DROP CONSTRAINT IF EXISTS order_items_product_name_fkey CASCADE;

-- Drop the 'product_name' column from 'Order_Items'
ALTER TABLE Order_Items
    DROP COLUMN product_name;

-- Remove the primary key constraint on 'p_name' in 'Products'
ALTER TABLE Products
    DROP CONSTRAINT IF EXISTS products_pkey CASCADE;

-- Set 'p_id' as the new primary key for the 'Products' table
ALTER TABLE Products
    ADD PRIMARY KEY (p_id);

-- Add a foreign key constraint in 'Order_Items' linking 'product_id' to 'p_id' of 'Products'
ALTER TABLE Order_Items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES Products (p_id);

-- Ensure that 'p_name' in 'Products' remains not null
ALTER TABLE Products
    ALTER COLUMN p_name SET NOT NULL;

-- Add a unique constraint to 'p_name' in 'Products'
ALTER TABLE Products
    ADD CONSTRAINT unique_p_name UNIQUE (p_name);

-- Re-establish the primary key for 'Order_Items' using 'order_id' and 'product_id'
ALTER TABLE Order_Items
    ADD PRIMARY KEY (order_id, product_id);

ALTER TABLE Order_Items
    ADD COLUMN price MONEY NOT NULL DEFAULT 0;
ALTER TABLE Order_Items
    ADD COLUMN total MONEY NOT NULL DEFAULT 0;
-- or we can use
-- ALTER TABLE Order_Items
-- ADD COLUMN total MONEY GENERATED ALWAYS AS (price * amount) STORED;
-- In this case we will not have to set total, add constraint to check that total=price * amount, etc.

-- Update the price in Order_Items from the Products table
UPDATE Order_Items
SET price = (SELECT price from Products WHERE Products.p_id = Order_Items.product_id);

UPDATE Order_Items
SET total = price * amount;

ALTER TABLE Order_Items
    ADD CONSTRAINT check_total_correct CHECK (total = price * amount);

--TASK 4

UPDATE Products
SET p_name = 'product1'
WHERE p_name = 'p1';

DELETE
FROM Order_Items
WHERE order_id = 1
  AND product_id IN (SELECT p_id
                     FROM Products
                     WHERE p_name = 'p2');

DELETE
FROM Order_Items
WHERE order_id = 2;
DELETE
FROM Orders
WHERE o_id = 2;

UPDATE Products
SET price = 5
WHERE p_name = 'product1';

UPDATE Order_Items
SET
    price = (SELECT price FROM Products WHERE p_name = 'product1'),
    total = (SELECT price FROM Products WHERE p_name = 'product1') * amount
WHERE product_id = (SELECT p_id FROM Products WHERE p_name = 'product1');

INSERT INTO Orders (order_date)
VALUES (CURRENT_DATE);
INSERT INTO Order_Items (order_id, product_id, amount, price, total)
VALUES ((SELECT o_id FROM Orders ORDER BY o_id DESC LIMIT 1),
        (SELECT p_id FROM Products WHERE p_name = 'product1'),
        3,
        (SELECT price FROM Products WHERE p_name = 'product1'),
        (SELECT price FROM Products WHERE p_name = 'product1') * 3);

SELECT *
FROM Orders;
SELECT *
FROM Products;
SELECT *
FROM Order_Items;
