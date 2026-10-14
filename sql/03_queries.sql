-- 03_queries.sql : 핵심 쿼리 15개
-- 실행: 01_schema.sql → 02_data.sql → 03_queries.sql 순서로
--       Q13, Q14가 데이터를 바꾸므로, 다시 실행할 때는 세 파일을 처음부터 다시 실행한다.
-- 각 쿼리 위에 "무엇을 확인하는 쿼리인지" 한 줄 설명을 붙였다.
-- 날짜 기준일은 2026-10-14로 고정했다 (실행하는 날에 따라 결과가 바뀌지 않도록).
--
-- 체크리스트 (과제 4. 기능 요구 사항)
-- [x] 기본 조회 4개 (Q01~Q04: WHERE, ORDER BY, LIMIT 포함)
-- [x] 조인 4개 (Q05~Q06 INNER, Q07~Q08 LEFT)
-- [x] 집계 3개 (Q09~Q11: COUNT, SUM, AVG + GROUP BY)
-- [x] 서브쿼리 1개 (Q12)
-- [x] 수정 및 삭제 2개 (Q13 UPDATE, Q14 DELETE)
-- [x] 인덱스 1개 (Q15)
-- [x] 실행 결과를 results/ 폴더에 저장 (results/results.md)

PRAGMA foreign_keys = ON;  -- SQLite 전용: FK 검사 켜기


-- ===== 기본 조회 =====

-- Q01. [기본 조회] 15,000원 이상인 책을 비싼 순으로 본다
SELECT title, price
FROM book
WHERE price >= 15000
ORDER BY price DESC;

-- Q02. [기본 조회] 제목에 "해리포터"가 들어간 책을 찾는다
SELECT title, price
FROM book
WHERE title LIKE '%해리포터%';

-- Q03. [기본 조회] 가장 비싼 책 TOP 3를 본다
SELECT title, price
FROM book
ORDER BY price DESC
LIMIT 3;

-- Q04. [기본 조회] 최근 30일(2026-09-14 ~ 2026-10-14) 대여 기록을 최신순으로 본다
SELECT id, member_id, book_id, rented_at
FROM rental
WHERE rented_at >= '2026-09-14'
ORDER BY rented_at DESC;


-- ===== 조인 =====

-- Q05. [INNER JOIN] 지금 대여 중인 책 목록 (반납 안 한 대여의 책 제목)
SELECT book.title, rental.rented_at
FROM rental
JOIN book ON rental.book_id = book.id
WHERE rental.returned_at IS NULL
ORDER BY rental.rented_at;

-- Q06. [INNER JOIN] 카테고리별 책을 본다 (책이 있는 카테고리만. Q08과 LEFT 한 단어만 다름)
SELECT category.name, book.title
FROM category
JOIN book ON book.category_id = category.id
ORDER BY category.id;

-- Q07. [LEFT JOIN] 대여 기록이 없는 회원도 포함해서 회원별 대여 번호를 본다
SELECT member.name, rental.id
FROM member
LEFT JOIN rental ON rental.member_id = member.id
ORDER BY member.id;

-- Q08. [LEFT JOIN] 책이 없는 카테고리도 포함해서 카테고리별 책을 본다 (Q06과 비교: 12줄 → 14줄)
SELECT category.name, book.title
FROM category
LEFT JOIN book ON book.category_id = category.id
ORDER BY category.id;


-- ===== 집계 =====

-- Q09. [집계] 회원별 대여 횟수를 많은 순으로 본다
SELECT member.name, COUNT(*)
FROM rental
JOIN member ON rental.member_id = member.id
GROUP BY member.name
ORDER BY COUNT(*) DESC;

-- Q10. [집계] 카테고리별 책 수, 가격 합계, 평균 가격을 본다
SELECT category.name, COUNT(*), SUM(book.price), AVG(book.price)
FROM book
JOIN category ON book.category_id = category.id
GROUP BY category.name;

-- Q11. [집계] 가장 많이 대여된 책 TOP 3를 본다
SELECT book.title, COUNT(*)
FROM rental
JOIN book ON rental.book_id = book.id
GROUP BY book.title
ORDER BY COUNT(*) DESC
LIMIT 3;


-- ===== 서브쿼리 =====

-- Q12. [서브쿼리] 대여 기록이 한 번도 없는 회원을 찾는다
SELECT name
FROM member
WHERE id NOT IN (SELECT member_id FROM rental);


-- ===== 수정 및 삭제 =====

-- Q13. [UPDATE] 15번 대여를 오늘(2026-10-14) 반납 처리한다
UPDATE rental
SET returned_at = '2026-10-14'
WHERE id = 15;

-- 확인 (15개에 세지 않음): 15번 대여의 반납일이 채워졌는지 본다
SELECT id, rented_at, returned_at
FROM rental
WHERE id = 15;

-- Q14. [DELETE] 대여 기록이 없는 회원 한서윤(9번)을 삭제한다 (가리키는 자식이 없어 FK에 막히지 않음)
DELETE FROM member
WHERE id = 9;

-- 확인 (15개에 세지 않음): 회원이 9명이 됐는지 본다
SELECT id, name
FROM member;


-- ===== 인덱스 =====

-- Q15. [인덱스] rental.member_id에 인덱스를 만든다
-- 이유: Q07, Q12처럼 회원 번호로 대여 기록(rental)을 찾는 일이 많아서 member_id로 바로 찾게 하려고
CREATE INDEX idx_rental_member_id ON rental(member_id);

-- 확인 (15개에 세지 않음, SQLite 전용): rental에 인덱스가 만들어졌는지 본다
PRAGMA index_list(rental);
