-- B6-1 | 카페 주문 데이터베이스 | 1단계: 빈 DB에 테이블을 만듭니다.
-- SQLite 전용: FK 검사는 연결마다 켜야 하며, BEGIN보다 먼저 실행해야 합니다.
PRAGMA foreign_keys = ON;

BEGIN;

-- 고객: 주문할 때마다 이름과 이메일을 반복 저장하지 않기 위한 부모 테이블입니다.
-- SQLite 전용: INTEGER PRIMARY KEY는 행 식별자이며, 생략하면 정수가 자동 배정됩니다.
CREATE TABLE customer (
    customer_id INTEGER PRIMARY KEY,  -- 고객 한 명을 구별하는 번호(PK)
    name TEXT NOT NULL,               -- 동명이인은 허용하므로 UNIQUE를 붙이지 않습니다.
    email TEXT NOT NULL UNIQUE,       -- 이 실습에서는 이메일 하나당 고객 한 명입니다.
    joined_on TEXT NOT NULL           -- SQLite 날짜 저장 방식: YYYY-MM-DD 문자열
);

-- 메뉴: 현재 판매 이름과 현재 단가를 저장합니다. 금액의 단위는 원입니다.
CREATE TABLE menu (
    menu_id INTEGER PRIMARY KEY,      -- 메뉴 한 종류를 구별하는 번호(PK)
    name TEXT NOT NULL UNIQUE,        -- 이 실습에서는 메뉴 이름의 중복을 막습니다.
    category TEXT NOT NULL,           -- coffee, non_coffee, ade, tea, dessert
    price_won INTEGER NOT NULL,
    -- SQLite 전용 typeof(): 실제 저장 자료형도 검사해 문자·소수 금액을 막습니다.
    CHECK (typeof(price_won) = 'integer' AND price_won > 0)
);

-- 주문: 한 번의 주문을 나타냅니다. 어떤 고객이 언제 주문했는지를 저장합니다.
CREATE TABLE cafe_order (
    order_id INTEGER PRIMARY KEY,     -- 주문 한 건을 구별하는 번호(PK)
    customer_id INTEGER NOT NULL,      -- 주문한 고객 번호(FK), 같은 고객의 여러 주문 허용
    ordered_at TEXT NOT NULL,          -- YYYY-MM-DD HH:MM:SS, 이 실습은 모두 한국 현지 시각
    -- RESTRICT: 주문이 남은 고객을 먼저 삭제하지 못하게 합니다.
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE RESTRICT
);

-- 주문상세: 한 주문에 들어간 메뉴 한 종류, 수량, 주문 당시 단가를 저장합니다.
CREATE TABLE order_item (
    order_item_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,        -- 어느 주문에 들어가는지 연결하는 FK
    menu_id INTEGER NOT NULL,         -- 어떤 메뉴인지 연결하는 FK
    quantity INTEGER NOT NULL,
    unit_price_won INTEGER NOT NULL,  -- 과거 금액 보존: 현재 menu.price_won과 구분합니다.
    -- SQLite 전용 typeof(): 수량은 양의 정수, 단가는 양의 정수 원만 허용합니다.
    CHECK (typeof(quantity) = 'integer' AND quantity > 0),
    CHECK (typeof(unit_price_won) = 'integer' AND unit_price_won > 0),
    -- 같은 주문의 같은 메뉴는 한 줄로 묶고 quantity를 늘리는 모델입니다.
    UNIQUE (order_id, menu_id),
    FOREIGN KEY (order_id) REFERENCES cafe_order(order_id) ON DELETE RESTRICT,
    FOREIGN KEY (menu_id) REFERENCES menu(menu_id) ON DELETE RESTRICT
);

COMMIT;
