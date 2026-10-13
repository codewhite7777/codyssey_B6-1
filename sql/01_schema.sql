-- 01_schema.sql : 도서 대여 DB 스키마
-- 실행: sqlite3 library.db 접속 후 .read sql/01_schema.sql
--
-- 관계 (1:N 3개, FK는 N 쪽 테이블에)
--   category (1) ──< book   (N)   book.category_id → category.id
--   book     (1) ──< rental (N)   rental.book_id   → book.id
--   member   (1) ──< rental (N)   rental.member_id → member.id
--
-- 체크리스트 (과제 4. 기능 요구 사항)
-- [x] 테이블 4개 이상 (category, member, book, rental)
-- [x] 모든 테이블에 PK
-- [x] FK로 1:N 관계 2개 이상 (3개)
-- [x] 컬럼 타입을 의미에 맞게 (TEXT, INTEGER, DATE)
-- [x] NOT NULL 1개 이상
-- [x] UNIQUE 1개 이상 (category.name, member.email)
-- [x] 부모 테이블을 먼저 만들기: category → member → book → rental
-- [x] DB 전용 문법은 주석으로 표시

PRAGMA foreign_keys = ON;  -- SQLite 전용: FK 검사 켜기 (접속할 때마다 필요)

-- 다시 실행할 수 있도록 기존 테이블을 지운다.
-- 지울 때는 자식 → 부모 순서 (만들 때의 반대)
DROP TABLE IF EXISTS rental;
DROP TABLE IF EXISTS book;
DROP TABLE IF EXISTS member;
DROP TABLE IF EXISTS category;

-- 책 분류 (부모)
CREATE TABLE category (
    id   INTEGER PRIMARY KEY,
    name TEXT    NOT NULL UNIQUE          -- 같은 이름의 카테고리가 두 번 생기지 않게
);

-- 회원 (부모)
CREATE TABLE member (
    id    INTEGER PRIMARY KEY,
    name  TEXT    NOT NULL,               -- 동명이인이 있으니 UNIQUE는 걸지 않음
    email TEXT    NOT NULL UNIQUE,        -- 회원을 구분하는 값이라 중복 금지
    phone TEXT                            -- 가족이 같이 쓸 수 있어 제약 없음
);

-- 책 (category의 자식, rental의 부모)
CREATE TABLE book (
    id          INTEGER PRIMARY KEY,
    title       TEXT    NOT NULL,
    category_id INTEGER NOT NULL,         -- 모든 책은 카테고리 하나에 속함
    price       INTEGER NOT NULL,         -- SUM, AVG에 쓸 숫자 칸 (원)
    FOREIGN KEY (category_id) REFERENCES category(id)
);

-- 대여 기록 (member, book의 자식)
-- 한 줄 = "누가 어떤 책을 언제 빌렸다"는 대여 한 건
CREATE TABLE rental (
    id          INTEGER PRIMARY KEY,
    member_id   INTEGER NOT NULL,
    book_id     INTEGER NOT NULL,
    rented_at   DATE    NOT NULL,         -- 'YYYY-MM-DD' 형식 글자로 저장
    returned_at DATE,                     -- NULL이면 아직 반납 안 함 (대여 중)
    FOREIGN KEY (member_id) REFERENCES member(id),
    FOREIGN KEY (book_id)   REFERENCES book(id)
);
