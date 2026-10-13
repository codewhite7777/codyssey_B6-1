B6-1 README 예시 실제 실행 기록 | 2026-10-13
Python 3.13.5 | SQLite 3.46.1 | Linux
검증 원문: README.md의 SQL 코드 블록을 직접 추출하여 실행
R01은 별도 빈 DB, 나머지는 schema.sql → seed.sql로 만든 별도 DB에서 실행
R12의 FK 오류는 의도된 성공 조건이며, 나머지 SQL 오류는 검사 실패로 처리
표 안의 NULL은 연결되는 값이 없음을 뜻함
verify.py의 58개 검사와 별도인 문서 예시 검사. 이 파일은 verify.py가 재생성하지 않음

=== R01 | CREATE TABLE: 고객을 저장할 빈 구조 만들기. 별도 빈 DB에서만 실행합니다. ===

-- R01 | CREATE TABLE: 고객을 저장할 빈 구조 만들기. 별도 빈 DB에서만 실행합니다.
CREATE TABLE customer (
    customer_id INTEGER PRIMARY KEY, -- SQLite: 고객 한 명을 구별하는 정수 번호
    name TEXT NOT NULL,              -- 이름을 NULL로 저장하지 못하게 합니다.
    email TEXT NOT NULL UNIQUE,      -- 이메일을 필수 값으로 받고 중복을 막습니다.
    joined_on TEXT NOT NULL          -- 가입일은 YYYY-MM-DD 문자열로 저장합니다.
);
OK (결과 표가 없는 SQL 문장)

SELECT COUNT(*) AS customer_count FROM customer;
customer_count
0
(1 rows)

PASS | R01: 기대 결과 확인

=== FK_SETTING | 연결의 FK 설정 조회 ===

-- SQLite 전용 설정: 이 연결에서 FK 검사 켜기
PRAGMA foreign_keys = ON;
OK (결과 표가 없는 SQL 문장)

-- 결과가 1이면 켜져 있습니다.
PRAGMA foreign_keys;
foreign_keys
1
(1 rows)

PASS | FK_SETTING: 기대 결과와 원본 보존 확인

=== R02 | INSERT: 새 고객 → 그 고객의 주문 → 주문상세를 입력하고 되돌립니다. ===

-- R02 | INSERT: 새 고객 → 그 고객의 주문 → 주문상세를 입력하고 되돌립니다.
PRAGMA foreign_keys = ON; -- SQLite 전용: BEGIN 전에 이 연결의 FK 검사를 켭니다.
OK (결과 표가 없는 SQL 문장)

BEGIN;
OK (결과 표가 없는 SQL 문장)

INSERT INTO customer (customer_id, name, email, joined_on)
VALUES (90, '연습고객', 'practice90@example.com', '2026-10-01');
OK (결과 표가 없는 SQL 문장)

INSERT INTO cafe_order (order_id, customer_id, ordered_at)
VALUES (90, 90, '2026-10-01 10:00:00'); -- 바로 위에 만든 고객 90번을 참조합니다.
OK (결과 표가 없는 SQL 문장)

INSERT INTO order_item (order_item_id, order_id, menu_id, quantity, unit_price_won)
VALUES (90, 90, 1, 2, 4000); -- 새 주문 90번과 기존 메뉴 1번을 연결합니다.
OK (결과 표가 없는 SQL 문장)

SELECT customer_id, name FROM customer WHERE customer_id = 90;
customer_id | name
90 | 연습고객
(1 rows)

SELECT order_id, customer_id FROM cafe_order WHERE order_id = 90;
order_id | customer_id
90 | 90
(1 rows)

SELECT order_id, menu_id, quantity FROM order_item WHERE order_item_id = 90;
order_id | menu_id | quantity
90 | 1 | 2
(1 rows)

ROLLBACK; -- 이번 BEGIN 이후 추가한 세 행을 모두 취소합니다.
OK (결과 표가 없는 SQL 문장)

SELECT COUNT(*) AS remaining_customers FROM customer WHERE customer_id = 90;
remaining_customers
0
(1 rows)

PASS | R02: 기대 결과와 원본 보존 확인

=== R03 | SELECT: Q01의 가격 조건과 Q04의 LIMIT를 조합한 학습 예제입니다. ===

-- R03 | SELECT: Q01의 가격 조건과 Q04의 LIMIT를 조합한 학습 예제입니다.
SELECT menu_id, name, price_won  -- 결과에 보여 줄 컬럼
FROM menu                      -- 읽을 테이블
WHERE price_won <= 4500         -- 조건을 만족하는 행만 남깁니다.
ORDER BY price_won ASC, menu_id ASC -- 가격이 같으면 메뉴 번호로 순서를 결정합니다.
LIMIT 3;                       -- SQLite 지원 문법: 정렬 결과에서 최대 3행
menu_id | name | price_won
10 | 크루아상 | 3500
1 | 아메리카노 | 4000
2 | 카페라테 | 4500
(3 rows)

PASS | R03: 기대 결과와 원본 보존 확인

=== R04 | JOIN 비교: 고객 1번과 10번만 골라 차이를 작게 확인합니다. ===

-- R04 | JOIN 비교: 고객 1번과 10번만 골라 차이를 작게 확인합니다.
SELECT c.customer_id, c.name, o.order_id
FROM customer AS c
INNER JOIN cafe_order AS o ON o.customer_id = c.customer_id
WHERE c.customer_id IN (1, 10)
ORDER BY c.customer_id, o.order_id;
customer_id | name | order_id
1 | 김민수 | 1
1 | 김민수 | 3
1 | 김민수 | 12
(3 rows)

SELECT c.customer_id, c.name, o.order_id
FROM customer AS c
LEFT JOIN cafe_order AS o ON o.customer_id = c.customer_id
WHERE c.customer_id IN (1, 10)
ORDER BY c.customer_id, o.order_id;
customer_id | name | order_id
1 | 김민수 | 1
1 | 김민수 | 3
1 | 김민수 | 12
10 | 임준서 | NULL
(4 rows)

PASS | R04: 기대 결과와 원본 보존 확인

=== R05 | COUNT 비교: 주문 없는 고객에게 왜 COUNT(*)를 쓰면 안 되는지 확인합니다. ===

-- R05 | COUNT 비교: 주문 없는 고객에게 왜 COUNT(*)를 쓰면 안 되는지 확인합니다.
SELECT c.customer_id, c.name,
       COUNT(*) AS joined_rows,        -- LEFT JOIN 결과에 남은 행 수
       COUNT(o.order_id) AS order_count -- NULL이 아닌 실제 주문 번호의 개수
FROM customer AS c
LEFT JOIN cafe_order AS o ON o.customer_id = c.customer_id
WHERE c.customer_id IN (1, 10)
GROUP BY c.customer_id, c.name
ORDER BY c.customer_id;
customer_id | name | joined_rows | order_count
1 | 김민수 | 3 | 3
10 | 임준서 | 1 | 0
(2 rows)

PASS | R05: 기대 결과와 원본 보존 확인

=== R06 | SUM과 AVG: 수량·판매금액 합계와 메뉴 가격 평균을 구분합니다. ===

-- R06 | SUM과 AVG: 수량·판매금액 합계와 메뉴 가격 평균을 구분합니다.
SELECT m.menu_id, m.name,
       SUM(i.quantity) AS sold_quantity,
       SUM(i.quantity * i.unit_price_won) AS sales_won
FROM menu AS m
INNER JOIN order_item AS i ON i.menu_id = m.menu_id
WHERE m.menu_id = 1
GROUP BY m.menu_id, m.name;
menu_id | name | sold_quantity | sales_won
1 | 아메리카노 | 5 | 20000
(1 rows)

SELECT category, COUNT(*) AS menu_count, AVG(price_won) AS average_price_won
FROM menu
WHERE category = 'coffee'
GROUP BY category;
category | menu_count | average_price_won
coffee | 5 | 4600.0
(1 rows)

PASS | R06: 기대 결과와 원본 보존 확인

=== R07 | NOT EXISTS: 한 번도 주문하지 않은 고객을 찾습니다. ===

-- R07 | NOT EXISTS: 한 번도 주문하지 않은 고객을 찾습니다.
SELECT c.customer_id, c.name
FROM customer AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM cafe_order AS o
    WHERE o.customer_id = c.customer_id
)
ORDER BY c.customer_id;
customer_id | name
10 | 임준서
11 | 서예린
12 | 장우진
(3 rows)

PASS | R07: 기대 결과와 원본 보존 확인

=== R08 | UPDATE: 현재 가격을 바꾸되 과거 단가는 유지되는지 확인하고 원복합니다. ===

-- R08 | UPDATE: 현재 가격을 바꾸되 과거 단가는 유지되는지 확인하고 원복합니다.
BEGIN;
OK (결과 표가 없는 SQL 문장)

SELECT 'before' AS phase, price_won FROM menu WHERE menu_id = 1;
phase | price_won
before | 4000
(1 rows)

UPDATE menu
SET price_won = 4500
WHERE menu_id = 1;
OK (결과 표가 없는 SQL 문장)

SELECT 'after' AS phase, m.price_won, i.unit_price_won
FROM menu AS m
INNER JOIN order_item AS i ON i.menu_id = m.menu_id
WHERE i.order_item_id = 1;
phase | price_won | unit_price_won
after | 4500 | 4000
(1 rows)

ROLLBACK;
OK (결과 표가 없는 SQL 문장)

SELECT 'restored' AS phase, price_won FROM menu WHERE menu_id = 1;
phase | price_won
restored | 4000
(1 rows)

PASS | R08: 기대 결과와 원본 보존 확인

=== R09 | DELETE: 주문이 없는 고객 12번을 지웠다가 되돌립니다. ===

-- R09 | DELETE: 주문이 없는 고객 12번을 지웠다가 되돌립니다.
PRAGMA foreign_keys = ON; -- SQLite 전용: 삭제에서도 참조 규칙을 검사합니다.
OK (결과 표가 없는 SQL 문장)

BEGIN;
OK (결과 표가 없는 SQL 문장)

SELECT 'before' AS phase, COUNT(*) AS target_count FROM customer WHERE customer_id = 12;
phase | target_count
before | 1
(1 rows)

DELETE FROM customer WHERE customer_id = 12;
OK (결과 표가 없는 SQL 문장)

SELECT 'after' AS phase, COUNT(*) AS target_count FROM customer WHERE customer_id = 12;
phase | target_count
after | 0
(1 rows)

ROLLBACK;
OK (결과 표가 없는 SQL 문장)

SELECT 'restored' AS phase, COUNT(*) AS target_count FROM customer WHERE customer_id = 12;
phase | target_count
restored | 1
(1 rows)

PASS | R09: 기대 결과와 원본 보존 확인

=== R10 | 인덱스: 주문 기간 검색에서 사용할 시각 검색 경로를 추가합니다. ===

-- R10 | 인덱스: 주문 기간 검색에서 사용할 시각 검색 경로를 추가합니다.
-- SQLite 지원 확장 문법 IF NOT EXISTS: 같은 이름이 이미 있으면 중복 생성하지 않습니다.
CREATE INDEX IF NOT EXISTS idx_cafe_order_ordered_at ON cafe_order(ordered_at);
OK (결과 표가 없는 SQL 문장)

PRAGMA index_info('idx_cafe_order_ordered_at'); -- SQLite 전용: 인덱스 컬럼 확인
seqno | cid | name
0 | 2 | ordered_at
(1 rows)

EXPLAIN QUERY PLAN -- SQLite 전용: 엔진이 선택한 조회 계획 확인
SELECT order_id, customer_id, ordered_at
FROM cafe_order
WHERE ordered_at >= '2026-10-01 00:00:00'
  AND ordered_at < '2026-10-03 00:00:00'
ORDER BY ordered_at, order_id;
id | parent | notused | detail
4 | 0 | 0 | SEARCH cafe_order USING INDEX idx_cafe_order_ordered_at (ordered_at>? AND ordered_at<?)
(1 rows)

PASS | R10: 기대 결과와 원본 보존 확인

=== R11 | 보너스: R07의 NOT EXISTS와 같은 고객을 LEFT JOIN으로 찾습니다. ===

-- R11 | 보너스: R07의 NOT EXISTS와 같은 고객을 LEFT JOIN으로 찾습니다.
SELECT c.customer_id, c.name
FROM customer AS c
LEFT JOIN cafe_order AS o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;
customer_id | name
10 | 임준서
11 | 서예린
12 | 장우진
(3 rows)

PASS | R11: 기대 결과와 원본 보존 확인

=== R12 | 의도된 FK 오류: 기본 샘플에는 고객 999번이 없습니다. ===

-- R12 | 의도된 FK 오류: 기본 샘플에는 고객 999번이 없습니다.
PRAGMA foreign_keys = ON; -- SQLite 전용: 연결에서 FK 검사 활성화
OK (결과 표가 없는 SQL 문장)

INSERT INTO cafe_order (order_id, customer_id, ordered_at)
VALUES (90, 999, '2026-10-01 10:00:00');
EXPECTED ERROR: FOREIGN KEY constraint failed

PASS | R12: 기대 결과와 원본 보존 확인

=== R13 | Q07 해설: 고객 → 주문 → 상세 → 메뉴의 네 표를 연결합니다. ===

-- R13 | Q07 해설: 고객 → 주문 → 상세 → 메뉴의 네 표를 연결합니다.
SELECT c.name AS customer_name, o.order_id, m.name AS menu_name,
       i.quantity, i.quantity * i.unit_price_won AS line_total_won
FROM customer AS c
INNER JOIN cafe_order AS o ON o.customer_id = c.customer_id
INNER JOIN order_item AS i ON i.order_id = o.order_id
INNER JOIN menu AS m ON m.menu_id = i.menu_id
WHERE c.customer_id = 1
ORDER BY o.order_id, i.order_item_id;
customer_name | order_id | menu_name | quantity | line_total_won
김민수 | 1 | 아메리카노 | 2 | 8000
김민수 | 1 | 크루아상 | 1 | 3500
김민수 | 3 | 바닐라라테 | 1 | 5000
김민수 | 3 | 크루아상 | 2 | 7000
김민수 | 12 | 아메리카노 | 1 | 4000
김민수 | 12 | 카페라테 | 1 | 4500
(6 rows)

PASS | R13: 기대 결과와 원본 보존 확인

PASS | R07과 R11의 결과 전체 일치
PASS | 전체 고객 JOIN 비교: LEFT 15행 / INNER 12행
PASS | 전체 주문상세 금액 합계: 145000원

결과: README R01~R13 13개 예제 통과 + FK 설정 SQL 통과 + 교차 확인 3개 통과.
원본 행·트랜잭션 보존 확인. R12의 의도된 FK 오류 외 예상하지 않은 SQL 오류 0개.
미검증: 사용자 OS의 CLI·GUI 실행 및 GitHub 화면의 Mermaid 렌더링.
