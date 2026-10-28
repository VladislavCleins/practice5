-- Практическая работа №5. Связи таблиц и JOIN
-- customers и products уже есть. Файл выполнять один раз.

-- 1. Создание таблиц

CREATE TABLE orders (
  order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(30) NOT NULL DEFAULT 'new',
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
  order_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES orders(order_id),
  product_id BIGINT NOT NULL REFERENCES products(product_id),
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0)
);

-- 2. Данные: 12 заказов и 28 позиций
-- Клиенты 4, 6, 10 без заказов; товары 10, 12, 19, 22, 28 без продаж

INSERT INTO orders (customer_id, order_date, status) VALUES
(1,  '2026-03-05', 'paid'),
(1,  '2026-04-18', 'shipped'),
(2,  '2026-04-02', 'paid'),
(3,  '2026-05-10', 'shipped'),
(3,  '2026-06-21', 'new'),
(5,  '2026-05-25', 'paid'),
(7,  '2026-06-02', 'cancelled'),
(7,  '2026-07-14', 'paid'),
(8,  '2026-08-09', 'shipped'),
(9,  '2026-09-03', 'paid'),
(11, '2026-09-27', 'new'),
(12, '2026-10-12', 'paid');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1,  1,  1, 52990.00),
(1,  3,  2, 3990.00),
(1,  4,  1, 1990.00),
(2,  2,  1, 24990.00),
(2,  5,  2, 8990.00),
(3,  15, 1, 17990.00),
(3,  17, 2, 4990.00),
(4,  6,  1, 89990.00),
(4,  11, 1, 5990.00),
(4,  18, 1, 3290.00),
(5,  7,  2, 15990.00),
(5,  9,  1, 15990.00),
(6,  13, 1, 32990.00),
(6,  14, 1, 54990.00),
(7,  16, 1, 69990.00),
(7,  23, 2, 12990.00),
(8,  20, 1, 99990.00),
(8,  24, 1, 7490.00),
(8,  4,  3, 1990.00),
(9,  8,  1, 42990.00),
(9,  21, 1, 119990.00),
(10, 25, 1, 129990.00),
(10, 3,  1, 3990.00),
(10, 17, 1, 4990.00),
(11, 1,  1, 52990.00),
(11, 5,  1, 8990.00),
(12, 26, 2, 5990.00),
(12, 27, 1, 3490.00);

-- Контроль: 12 заказов, 28 позиций
SELECT (SELECT COUNT(*) FROM orders) AS orders_count,
       (SELECT COUNT(*) FROM order_items) AS items_count;

-- 3. JOIN-запросы

-- 3.1. INNER JOIN 2 таблиц: заказы и имена клиентов
SELECT o.order_id, o.order_date, o.status, c.full_name
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
ORDER BY o.order_id;

-- 3.2. INNER JOIN 4 таблиц: клиент, заказ, товар, количество, цена
SELECT c.full_name, o.order_id, p.product_name, oi.quantity, oi.unit_price
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
ORDER BY o.order_id, oi.order_item_id;

-- 3.3. LEFT JOIN: все клиенты и число их заказов
SELECT c.customer_id, c.full_name, COUNT(o.order_id) AS orders_count
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY c.customer_id;

-- 3.4. Anti-join: клиенты без заказов
SELECT c.customer_id, c.full_name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- 3.5. Anti-join: товары без продаж
SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
WHERE oi.order_item_id IS NULL
ORDER BY p.product_id;

-- 3.6. Условие в ON: все клиенты и только их оплаченные заказы (12 строк)
SELECT c.full_name, o.order_id, o.status
FROM customers c
LEFT JOIN orders o
  ON o.customer_id = c.customer_id
 AND o.status = 'paid'
ORDER BY c.customer_id, o.order_id;

-- 3.7. Условие в WHERE: клиенты без оплаченных заказов пропадают (6 строк)
SELECT c.full_name, o.order_id, o.status
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.status = 'paid'
ORDER BY c.customer_id, o.order_id;

-- 3.8. Контроль числа строк до и после JOIN
SELECT (SELECT COUNT(*) FROM customers) AS customers,
       (SELECT COUNT(*) FROM orders) AS orders,
       (SELECT COUNT(*) FROM order_items) AS items,
       (SELECT COUNT(*) FROM orders o
          JOIN customers c ON c.customer_id = o.customer_id) AS inner_2_tables,
       (SELECT COUNT(*) FROM customers c
          JOIN orders o ON o.customer_id = c.customer_id
          JOIN order_items oi ON oi.order_id = o.order_id
          JOIN products p ON p.product_id = oi.product_id) AS inner_4_tables,
       (SELECT COUNT(*) FROM customers c
          LEFT JOIN orders o ON o.customer_id = c.customer_id) AS left_customers_orders;

-- 4. Аналитические отчёты

-- 4.1. Сумма каждого заказа
SELECT o.order_id,
       SUM(oi.quantity * oi.unit_price) AS order_total
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_id
ORDER BY order_total DESC;

-- 4.2. Заказы и сумма покупок по клиентам (HAVING: от 100000)
SELECT c.full_name,
       COUNT(DISTINCT o.order_id) AS orders,
       SUM(oi.quantity) AS units,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.full_name
HAVING SUM(oi.quantity * oi.unit_price) >= 100000
ORDER BY revenue DESC;

-- 4.3. Единицы и выручка по товарам
SELECT p.product_id, p.product_name,
       SUM(oi.quantity) AS units,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY revenue DESC;

-- 4.4. Выручка по категориям (заказы paid и shipped)
SELECT p.category,
       COUNT(DISTINCT o.order_id) AS orders,
       SUM(oi.quantity) AS units,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.status IN ('paid', 'shipped')
GROUP BY p.category
ORDER BY revenue DESC;

-- 4.5. Продажи по городам за период: май - июль 2026
SELECT c.city,
       COUNT(DISTINCT o.order_id) AS orders,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_date >= '2026-05-01'
  AND o.order_date <  '2026-08-01'
GROUP BY c.city
ORDER BY revenue DESC;

-- 4.6. Полный каталог с нулевыми продажами
SELECT p.product_id, p.product_name, p.category,
       COALESCE(SUM(oi.quantity), 0) AS units,
       COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS revenue
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC, p.product_id;

-- 5. Проверка отчётов детализацией

-- 5.1. Отчёт 4.1: заказ 4 = 99270 (89990 + 5990 + 3290)
SELECT order_id, product_id, quantity, unit_price,
       quantity * unit_price AS line_total
FROM order_items
WHERE order_id = 4;

-- 5.2. Отчёт 4.2: Ольга Новикова = 209420 (95970 + 113450)
SELECT o.order_id, p.product_name, oi.quantity, oi.unit_price,
       oi.quantity * oi.unit_price AS line_total
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE c.customer_id = 7
ORDER BY o.order_id, oi.order_item_id;

-- 5.3. Общая выручка = сумма заказов из отчёта 4.1 (957940)
SELECT SUM(quantity * unit_price) AS total_revenue FROM order_items;

-- 6. Проверка FOREIGN KEY: заказ несуществующего клиента (должна быть ошибка)
INSERT INTO orders (customer_id) VALUES (9999);
