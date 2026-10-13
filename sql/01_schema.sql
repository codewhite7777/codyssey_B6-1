-- 01_schema.sql : 도서 대여 DB 스키마
-- 실행: sqlite3 library.db 접속 후 .read sql/01_schema.sql
--
-- 체크리스트 (과제 4. 기능 요구 사항)
-- [ ] 테이블 4개 이상 (category, member, book, rental)
-- [ ] 모든 테이블에 PK
-- [ ] FK로 1:N 관계 2개 이상 (FK는 N 쪽 테이블에)
-- [ ] 컬럼 타입을 의미에 맞게 (TEXT, INTEGER, DATE 등)
-- [ ] NOT NULL 1개 이상
-- [ ] UNIQUE 1개 이상
-- [ ] 부모 테이블을 먼저 만들기: category → member → book → rental
-- [ ] DB 전용 문법을 쓰면 주석으로 표시 (예: PRAGMA는 SQLite 전용)

PRAGMA foreign_keys = ON;  -- SQLite 전용: FK 검사 켜기

-- 여기에 CREATE TABLE 작성
