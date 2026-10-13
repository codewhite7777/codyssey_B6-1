-- 02_data.sql : 샘플 데이터
-- 실행: 01_schema.sql 다음에 .read sql/02_data.sql
--
-- 체크리스트 (과제 4. 기능 요구 사항)
-- [ ] 테이블마다 10행 이상
-- [ ] 부모 먼저 넣기: category → member → book → rental
-- [ ] FK로 연결된 데이터가 실제로 관계를 갖도록 (없는 번호 참조 X)
-- [ ] 쿼리 결과가 의미 있게 나오도록 섞기
--     - 대여를 많이 한 회원 / 한 번도 안 한 회원 (LEFT JOIN, 서브쿼리용)
--     - 반납한 기록 / 아직 안 한 기록 returned_at IS NULL (대여 중인 책 조회용)
--     - 아무도 안 빌린 책, 책이 없는 카테고리

PRAGMA foreign_keys = ON;  -- SQLite 전용: FK 검사 켜기

-- 여기에 INSERT 작성
