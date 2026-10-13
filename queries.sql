-- B6-1 | 3단계: seed.sql까지 실행한 DB에서 Q01~Q15를 순서대로 실행합니다.
-- 분류: 기본 조회 4 + 조인 4 + 집계 3 + 서브쿼리 1 + 수정/삭제 2 + 인덱스 1.
-- Q13~Q15의 추가 SELECT/PRAGMA/EXPLAIN은 결과 확인용이며 15개에 중복 계산하지 않습니다.
-- SQLite 전용: 연결마다 FK 검사 활성화. Q13·Q14는 실습 후 ROLLBACK으로 원복합니다.
PRAGMA foreign_keys = ON;

-- Q01 | 기본 조회 | 4,500원 이하 메뉴를 저렴한 순서로 확인합니다.
SELECT menu_id, name, price_won
FROM menu
WHERE price_won <= 4500
ORDER BY price_won ASC, menu_id ASC;

-- Q02 | 기본 조회 | 이름에 '라테'가 들어간 메뉴를 검색합니다.
-- LIKE의 %는 앞뒤에 다른 글자가 있어도 된다는 뜻입니다.
SELECT menu_id, name, price_won
FROM menu
WHERE name LIKE '%라테%'
ORDER BY menu_id;

-- Q03 | 기본 조회 | 10월 1일과 2일의 주문을 시간순으로 확인합니다.
-- 시작은 포함(>=), 다음 날 0시는 제외(<)하여 10월 2일 전체를 포함합니다.
SELECT order_id, customer_id, ordered_at
FROM cafe_order
WHERE ordered_at >= '2026-10-01 00:00:00'
  AND ordered_at < '2026-10-03 00:00:00'
ORDER BY ordered_at, order_id;

-- Q04 | 기본 조회 | 가장 최근 주문 3건을 확인합니다.
-- LIMIT는 SQLite에서 지원하며 SQL 표준의 FETCH FIRST와 문법이 다릅니다.
-- 시간이 같으면 order_id로 순서를 결정하여 결과를 일정하게 만듭니다.
SELECT order_id, customer_id, ordered_at
FROM cafe_order
ORDER BY ordered_at DESC, order_id DESC
LIMIT 3;

-- Q05 | 조인 | 주문 1~4번에 주문 고객의 이름을 붙입니다(INNER JOIN).
-- c와 o는 테이블의 짧은 별명이며, ON은 연결할 번호의 일치 조건입니다.
SELECT o.order_id, c.customer_id, c.name, o.ordered_at
FROM cafe_order AS o
INNER JOIN customer AS c ON c.customer_id = o.customer_id
WHERE o.order_id <= 4
ORDER BY o.order_id;

-- Q06 | 조인 | 1번 주문의 메뉴명, 수량, 주문 당시 단가, 줄별 금액을 확인합니다.
SELECT i.order_id, m.name, i.quantity, i.unit_price_won,
       i.quantity * i.unit_price_won AS line_total_won
FROM order_item AS i
INNER JOIN menu AS m ON m.menu_id = i.menu_id
WHERE i.order_id = 1
ORDER BY i.order_item_id;

-- Q07 | 조인 | 1번 고객이 여러 주문에서 구매한 메뉴를 4개 테이블로 연결합니다.
-- 고객 -> 주문 -> 주문상세 -> 메뉴 순서로 필요한 정보를 찾아갑니다.
SELECT c.name AS customer_name, o.order_id, m.name AS menu_name,
       i.quantity, i.quantity * i.unit_price_won AS line_total_won
FROM customer AS c
INNER JOIN cafe_order AS o ON o.customer_id = c.customer_id
INNER JOIN order_item AS i ON i.order_id = o.order_id
INNER JOIN menu AS m ON m.menu_id = i.menu_id
WHERE c.customer_id = 1
ORDER BY o.order_id, i.order_item_id;

-- Q08 | 조인 | 주문이 없는 고객까지 모두 남겨 고객과 주문을 연결합니다(LEFT JOIN).
-- 대응하는 주문이 없으면 order_id는 NULL입니다. 0번 주문이 있다는 뜻이 아닙니다.
SELECT c.customer_id, c.name, o.order_id
FROM customer AS c
LEFT JOIN cafe_order AS o ON o.customer_id = c.customer_id
ORDER BY c.customer_id, o.order_id;

-- Q09 | 집계 | 주문이 없는 고객을 0건으로 포함하여 고객별 주문 횟수를 셉니다.
-- COUNT(o.order_id)는 NULL을 세지 않습니다. COUNT(*)는 연결 결과의 행을 셉니다.
SELECT c.customer_id, c.name, COUNT(o.order_id) AS order_count
FROM customer AS c
LEFT JOIN cafe_order AS o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY order_count DESC, c.customer_id;

-- Q10 | 집계 | 판매된 메뉴별 수량과 판매금액을 합산하여 금액 순으로 정렬합니다.
-- 현재 메뉴 가격이 아닌 주문 당시 단가를 사용합니다. 미판매 메뉴는 제외됩니다.
SELECT m.menu_id, m.name, SUM(i.quantity) AS sold_quantity,
       SUM(i.quantity * i.unit_price_won) AS sales_won
FROM menu AS m
INNER JOIN order_item AS i ON i.menu_id = m.menu_id
GROUP BY m.menu_id, m.name
ORDER BY sales_won DESC, m.menu_id;

-- Q11 | 집계 | 메뉴 분류별 등록 메뉴 수와 현재 메뉴 단가의 평균을 확인합니다.
-- AVG(price_won)는 메뉴 종류별 가격 평균이지, 주문금액 평균이나 판매가중평균은 아닙니다.
SELECT category, COUNT(*) AS menu_count, AVG(price_won) AS average_price_won
FROM menu
GROUP BY category
ORDER BY category;

-- Q12 | 서브쿼리 | 주문이 한 번도 없는 고객을 찾습니다(NOT EXISTS).
-- 바깥 고객 c와 연결되는 주문이 안쪽 SELECT에 하나도 없을 때만 남깁니다.
SELECT c.customer_id, c.name
FROM customer AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM cafe_order AS o
    WHERE o.customer_id = c.customer_id
)
ORDER BY c.customer_id;

-- Q13 | 수정 | 아메리카노 현재 가격을 4,000원에서 4,500원으로 바꿔 확인하고 원복합니다.
-- BEGIN~ROLLBACK 전체를 함께 실행해야 원본 데이터가 보존됩니다.
BEGIN;
SELECT 'before' AS phase, menu_id, price_won FROM menu WHERE menu_id = 1;
UPDATE menu SET price_won = 4500 WHERE menu_id = 1;
-- SQLite 전용 changes(): 직전 UPDATE가 실제로 바꾼 행 수를 확인합니다.
SELECT changes() AS updated_rows;
SELECT 'after' AS phase, m.price_won AS current_price_won,
       i.unit_price_won AS ordered_price_won
FROM menu AS m
INNER JOIN order_item AS i ON i.menu_id = m.menu_id
WHERE i.order_item_id = 1;
ROLLBACK;
SELECT 'restored' AS phase, menu_id, price_won FROM menu WHERE menu_id = 1;

-- Q14 | 삭제 | 주문이 없는 12번 고객을 삭제해 확인하고 원복합니다.
-- 참조 중인 고객을 삭제하면 FK가 막습니다. 이 고객은 주문이 없어 삭제 가능합니다.
BEGIN;
SELECT 'before' AS phase, COUNT(*) AS target_count FROM customer WHERE customer_id = 12;
DELETE FROM customer WHERE customer_id = 12;
-- SQLite 전용 changes(): 직전 DELETE로 실제 삭제된 행 수를 확인합니다.
SELECT changes() AS deleted_rows;
SELECT 'after' AS phase, COUNT(*) AS target_count FROM customer WHERE customer_id = 12;
ROLLBACK;
SELECT 'restored' AS phase, COUNT(*) AS target_count FROM customer WHERE customer_id = 12;

-- Q15 | 인덱스 | 주문 시각 인덱스를 만들고 적용 컬럼과 조회 계획을 확인합니다.
-- 적용 이유: 주문 기간 검색(Q03)에서 ordered_at 범위를 빠르게 찾기 위한 인덱스입니다.
-- IF NOT EXISTS는 SQLite 지원 확장 문법이며 재실행 시 같은 인덱스의 중복 생성을 막습니다.
CREATE INDEX IF NOT EXISTS idx_cafe_order_ordered_at ON cafe_order(ordered_at);
-- SQLite 전용 PRAGMA: 인덱스가 어느 컬럼에 걸렸는지 확인합니다.
PRAGMA index_info('idx_cafe_order_ordered_at');
-- SQLite 전용 EXPLAIN QUERY PLAN: 실행 계획 확인용이며 실제 시간 측정 결과는 아닙니다.
EXPLAIN QUERY PLAN
SELECT order_id, customer_id, ordered_at
FROM cafe_order
WHERE ordered_at >= '2026-10-01 00:00:00'
  AND ordered_at < '2026-10-03 00:00:00'
ORDER BY ordered_at, order_id;
