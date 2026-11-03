CREATE DATABASE air_cargo;
USE air_cargo;
show databases;

SHOW TABLES;

DESC customer;
DESC passengers_on_flights;
DESC routes;
DESC ticket_details;

SELECT * FROM customer LIMIT 10;
SELECT * FROM passengers_on_flights LIMIT 10;
SELECT * FROM routes LIMIT 10;
SELECT * FROM ticket_details LIMIT 10;

/*
Question 2
Creating route_details table with:
1. Unique constraint on route_id
2. Check constraint on flight number
3. Distance must be greater than 0
*/

CREATE TABLE route_details (

    route_id INT NOT NULL,

    flight_num INT NOT NULL,

    origin_airport VARCHAR(50) NOT NULL,

    destination_airport VARCHAR(50) NOT NULL,

    aircraft_id VARCHAR(50) NOT NULL,

    distance_miles INT NOT NULL,

    CONSTRAINT uq_route_id
        UNIQUE(route_id),

    CONSTRAINT chk_flight_num
        CHECK (flight_num > 0),

    CONSTRAINT chk_distance
        CHECK (distance_miles > 0)
);

/*
Question 3

Retrieve all passengers travelling
between routes 1 and 25.
*/

SELECT *
FROM passengers_on_flights
WHERE route_id BETWEEN 1 AND 25;

/*
Question 4

Count Business Class passengers
and calculate total revenue.
*/

SELECT

    COUNT(customer_id) AS total_passengers,

    SUM(no_of_tickets * price_per_ticket)
    AS total_revenue

FROM ticket_details

WHERE class_id = 'Business';

/*
Question 5

Combine first and last names.
*/

SELECT

customer_id,

CONCAT(first_name,' ',last_name)
AS full_name

FROM customer;

/*
Question 6

Use INNER JOIN to get customers
who booked tickets.
*/

SELECT DISTINCT

c.customer_id,
c.first_name,
c.last_name

FROM customer c

INNER JOIN ticket_details t

ON c.customer_id = t.customer_id;

/*
Question 7

Find customers who booked
with Emirates.
*/

SELECT

c.customer_id,
c.first_name,
c.last_name,
t.brand

FROM customer c

INNER JOIN ticket_details t

ON c.customer_id = t.customer_id

WHERE t.brand = 'Emirates';

/*
Question 8

Identify Economy Plus travellers.
Use GROUP BY and HAVING.
*/

SELECT

customer_id,

COUNT(*) AS total_trips

FROM passengers_on_flights

WHERE class_id='Economy Plus'

GROUP BY customer_id

HAVING COUNT(*) >= 1;

/*
Question 9

Determine whether
revenue exceeds 10000.
*/

SELECT

IF(

SUM(no_of_tickets * price_per_ticket) > 10000,

'Revenue Crossed 10000',

'Revenue Below 10000'

) AS revenue_status

FROM ticket_details;

/*
Question 10

Create new database user.
*/

CREATE USER 'aircargo_user'@'localhost'
IDENTIFIED BY 'AirCargo@123';

/*
Grant privileges
*/

GRANT ALL PRIVILEGES

ON air_cargo.*

TO 'aircargo_user'@'localhost';

FLUSH PRIVILEGES;
/*
Question 11

Find highest ticket price
for each class.
*/

SELECT

class_id,

price_per_ticket,

MAX(price_per_ticket)

OVER(

PARTITION BY class_id

) AS max_ticket_price

FROM ticket_details;

/*
Question 12

Index improves search speed.
*/

CREATE INDEX idx_route_id
ON passengers_on_flights(route_id);

SELECT *
FROM passengers_on_flights
WHERE route_id = 4;

/*
Question 13

Display execution plan.
*/

EXPLAIN

SELECT *

FROM passengers_on_flights

WHERE route_id = 4;

/*
Question 14

Calculate total ticket sales
for customers and aircrafts.
*/

SELECT

customer_id,

aircraft_id,

SUM(price_per_ticket * no_of_tickets)
AS total_price

FROM ticket_details

GROUP BY

customer_id,
aircraft_id

WITH ROLLUP;

/*
Question 15

View containing only
Business Class customers.
*/

CREATE VIEW business_class_customers AS

SELECT

c.customer_id,
c.first_name,
c.last_name,
t.brand,
t.class_id

FROM customer c

INNER JOIN ticket_details t

ON c.customer_id=t.customer_id

WHERE t.class_id='Business';

SELECT *
FROM business_class_customers;

/*
Question 16

Return passengers between
route ranges.

Return error if table missing.
*/

DELIMITER $$

CREATE PROCEDURE GetPassengersByRoute(

IN startRoute INT,
IN endRoute INT

)

BEGIN

IF EXISTS (

SELECT *

FROM information_schema.tables

WHERE table_name='passengers_on_flights'

AND table_schema=DATABASE()

)

THEN

SELECT *

FROM passengers_on_flights

WHERE route_id BETWEEN startRoute
AND endRoute;

ELSE

SIGNAL SQLSTATE '45000'

SET MESSAGE_TEXT =
'Table does not exist';

END IF;

END $$

DELIMITER ;

CALL GetPassengersByRoute(1,25);

/*
Question 17

Routes greater than 2000 miles.
*/

DELIMITER $$

CREATE PROCEDURE LongDistanceRoutes()

BEGIN

SELECT *

FROM routes

WHERE distance_miles > 2000;

END $$

DELIMITER ;

CALL LongDistanceRoutes();

/*
Question 18

SDT = 0-2000

IDT = 2001-6500

LDT = Above 6500
*/

DELIMITER $$

CREATE PROCEDURE RouteCategory()

BEGIN

SELECT

route_id,

flight_num,

distance_miles,

CASE

WHEN distance_miles >=0
AND distance_miles <=2000

THEN 'SDT'

WHEN distance_miles >2000
AND distance_miles <=6500

THEN 'IDT'

ELSE 'LDT'

END AS travel_category

FROM routes;

END $$

DELIMITER ;

CALL RouteCategory();

/*
Question 19

Returns Yes or No
for complimentary service.
*/

DELIMITER $$

CREATE FUNCTION ComplimentaryService(

className VARCHAR(50)

)

RETURNS VARCHAR(10)

DETERMINISTIC

BEGIN

RETURN

IF(

className IN
('Business','Economy Plus'),

'Yes',

'No'

);

END $$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE CustomerComplimentaryService()

BEGIN

SELECT

p_date,

customer_id,

class_id,

ComplimentaryService(class_id)
AS complimentary_service

FROM ticket_details;

END $$

DELIMITER ;

CALL CustomerComplimentaryService();

/*
Question 20

Cursor retrieves first record
whose last name ends with Scott.
*/

DELIMITER $$

CREATE PROCEDURE FirstScottCustomer()

BEGIN

DECLARE v_customer_id INT;
DECLARE v_first_name VARCHAR(50);
DECLARE v_last_name VARCHAR(50);

DECLARE done INT DEFAULT FALSE;

DECLARE customer_cursor CURSOR FOR

SELECT

customer_id,
first_name,
last_name

FROM customer

WHERE last_name LIKE '%Scott';

DECLARE CONTINUE HANDLER
FOR NOT FOUND
SET done = TRUE;

OPEN customer_cursor;

FETCH customer_cursor

INTO

v_customer_id,
v_first_name,
v_last_name;

IF NOT done THEN

SELECT

v_customer_id AS customer_id,
v_first_name AS first_name,
v_last_name AS last_name;

END IF;

CLOSE customer_cursor;

END $$

DELIMITER ;

CALL FirstScottCustomer();

