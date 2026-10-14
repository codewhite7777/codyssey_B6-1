# 피어 평가 준비

평가 항목마다 **무엇을 보여주고, 어떻게 답할지**를 정리합니다. 쿼리 번호(Q01~Q15)는 [03_queries.sql](../sql/03_queries.sql) 기준입니다.

[← README](../README.md) · [개념 정리](concepts.md) · [연습 기록](practice.md)

---

## 평가 진행 순서 (시연)

평가 자리에서 이 순서대로 보여주면 항목 1~3이 차례로 채워집니다.

| 순서 | 할 것 | 보여주는 평가 항목 |
|---|---|---|
| 1 | README 맨 위 **진행 상황**과 **2. 최종 결과물** 표로 제출물 소개 | 항목 1 |
| 2 | 터미널에서 DB를 새로 만들고 세 파일 실행 (아래 명령) | 항목 1 |
| 3 | `01_schema.sql`을 열어 테이블 4개, PK, FK 3개, NOT NULL, UNIQUE 설명 | 항목 1, 2 |
| 4 | README 4-3의 **제약조건 확인 SQL 3개**를 직접 실행해서 막히는 것 시연 | 항목 1, 3 |
| 5 | `SELECT COUNT(*) FROM 테이블;`로 각 10행 이상 확인 | 항목 1 |
| 6 | **Q06과 Q08**을 실행해 INNER(12줄)와 LEFT(14줄) 차이 설명 | 항목 3 |
| 7 | **Q10**을 실행해 GROUP BY와 COUNT, SUM, AVG 설명 | 항목 3 |
| 8 | **Q11**로 가장 복잡한 쿼리를 단계별 설명 | 항목 4 |
| 9 | 나머지 쿼리는 [results/results.md](../results/results.md)로 결과 확인 | 항목 1 |
| 10 | 아래 항목 2~4의 질문에 답변 | 항목 2~4 |

**시연용 명령**

```bash
# 1. 레포 받기 (처음 한 번. 이미 있으면 폴더에서 git pull)
git clone https://github.com/codewhite7777/codyssey_b6-1.git
cd codyssey_b6-1

# 2. DB 열기 (sql/ 폴더가 있는 이 위치에서 실행)
rm -f library.db       # 이전 실행 결과 지우기 (Q13, Q14가 데이터를 바꾸므로)
sqlite3 library.db
```

```sql
PRAGMA foreign_keys = ON;
.mode table
.headers on
.nullvalue NULL        -- NULL을 빈칸 대신 NULL로 보이게
.read sql/01_schema.sql
.read sql/02_data.sql
.read sql/03_queries.sql
```

명령마다 하는 일은 [README 4-1](../README.md#4-1-db-환경-준비)에 정리했습니다.

쿼리 하나만 다시 보고 싶으면 `03_queries.sql`에서 해당 SQL을 복사해 붙여넣으면 됩니다.

---

## 항목 1. 결과물이 요구사항을 채우는가

| 평가 질문 | 상태 | 보여줄 곳 |
|---|---|---|
| 테이블 4개 이상, 각 테이블에 PK가 있는가? | ✅ | [01_schema.sql](../sql/01_schema.sql), [README 4-2](../README.md#4-2-데이터-모델스키마-설계) |
| FK 1:N 관계 2개 이상, 없는 값 참조가 실제로 막히는가? | ✅ 1:N 3개 | [README 4-3](../README.md#4-3-제약조건-적용)의 확인 SQL 실행 → `FOREIGN KEY constraint failed` |
| 각 테이블에 10행 이상 들어 있는가? | ✅ 10 / 10 / 12 / 15행 | [02_data.sql](../sql/02_data.sql), `SELECT COUNT(*) FROM 테이블;` |
| 쿼리 15개 (조회 4, 조인 4, 집계 3, 서브쿼리 1, 수정/삭제 2, 인덱스 1) | ✅ Q01~Q15 | [03_queries.sql](../sql/03_queries.sql) |
| 쿼리마다 실행 결과가 첨부되어 있는가? | ✅ | [results/results.md](../results/results.md) |

---

## 항목 2. 설계를 설명할 수 있는가

### 테이블을 왜 이렇게 나눴고, 각 테이블의 역할은?

엑셀 한 시트에 "회원 이름, 전화번호, 책 제목, 대여일"을 다 적으면 회원 정보가 대여할 때마다 반복되고, 번호가 바뀌면 모든 줄을 고쳐야 합니다. 그래서 **주제별로 나누고 번호로 연결**했습니다.

| 테이블 | 역할 | 한 줄 = |
|---|---|---|
| category | 책 분류 | 카테고리 하나 |
| member | 회원 정보 | 회원 한 명 |
| book | 책 정보 | 책 한 권 |
| rental | 누가 어떤 책을 언제 빌렸나 | **대여 한 건** (사건) |

rental은 회원과 책을 **연결하는 기록**입니다. 책에 회원 칸을 두면 책 한 권당 한 명밖에 못 적어서, 대여라는 사건을 따로 기록합니다.

### 1:N 관계가 실제로 어떤 의미인가?

| 관계 | 실제 의미 | 데이터 예시 |
|---|---|---|
| category 1 : N book | 카테고리 하나에 책 여러 권 | 소설 → 해리포터 2권, 어린왕자 |
| member 1 : N rental | 회원 한 명이 여러 번 빌림 | 김철수 → 대여 1, 3, 6, 12번 (4회) |
| book 1 : N rental | 책 한 권이 여러 번 대여됨 | 해리포터와 마법사의 돌 → 대여 1, 4, 7, 12번 (4회) |

FK는 항상 N 쪽에 둡니다. (`book.category_id`, `rental.member_id`, `rental.book_id`)

### 컬럼 타입은 왜 그렇게 골랐나?

| 칸 | 타입 | 이유 |
|---|---|---|
| id, `*_id` | INTEGER | 번호. FK로 같은 번호끼리 비교 |
| name, title, email, phone | TEXT | 글자. 전화번호는 계산하지 않고 앞의 0을 지키려고 TEXT |
| price | INTEGER | 글자로 저장하면 정렬과 비교가 **사전 순서로 조용히 틀림** ('9000'이 '15000'보다 위). SUM, AVG에도 사용 |
| rented_at, returned_at | DATE | 날짜. `'YYYY-MM-DD'` 형식이라 정렬, 비교가 날짜 순서대로 됨 |

### 인덱스는 어디에 걸었고 왜 그 칸인가?

Q15에서 `rental.member_id`에 걸었습니다.

- Q07, Q09, Q12처럼 **회원 기준으로 대여 기록을 찾는** JOIN, WHERE에서 이 칸으로 자주 찾기 때문
- PK인 `id`는 이미 자동으로 인덱스가 있어서 따로 걸 필요 없음
- 아무 데나 걸지 않는 이유: 넣고 바꿀 때마다 인덱스도 고쳐야 해서 INSERT, UPDATE가 느려짐

---

## 항목 3. 개념을 설명할 수 있는가

| 평가 질문 | 보여줄 것 | 개념 정리 |
|---|---|---|
| DB와 엑셀의 차이, 왜 나눠 저장하나 | 엑셀 한 시트 예시 vs 4개 테이블. 없는 회원 번호를 넣으면 DB는 막음 (README 4-3) | [개념 1](concepts.md#1-db는-엑셀과-뭐가-다른가-왜-테이블로-나눠-저장하나) |
| PK와 FK 구분, 1:N 연결을 내 스키마로 | PK = 내 번호(`member.id`), FK = 남의 번호(`rental.member_id`). 김철수 1명 → 대여 4건 | [개념 2](concepts.md#2-pk--fk--1n-관계는-데이터를-어떻게-연결하나) |
| INNER JOIN과 LEFT JOIN 차이를 결과로 | **Q06(INNER, 12줄)과 Q08(LEFT, 14줄)** 비교: 같은 book-category인데 LEFT에만 시집, 요리가 NULL로 남음. Q07에서는 박민수, 한서윤이 NULL | [개념 4](concepts.md#4-join과-group-by로-연결된-데이터를-한-번에-뽑는-방법) |
| GROUP BY와 COUNT, SUM, AVG 동작을 결과로 | **Q10**: 카테고리별 권수, 가격 합계, 평균을 보며 "같은 값끼리 더미 → 더미마다 계산". **Q09**: 회원별 COUNT | [개념 4](concepts.md#4-join과-group-by로-연결된-데이터를-한-번에-뽑는-방법) |

---

## 항목 4. 경험을 말할 수 있는가

### 가장 복잡했던 쿼리와 푸는 과정

**Q11 가장 많이 대여된 책 TOP 3**입니다. 결과: 해리포터와 마법사의 돌 4회, 해리포터와 비밀의 방 2회, 원피스 1권 2회.

```sql
SELECT book.title, COUNT(*)
FROM rental
JOIN book ON rental.book_id = book.id
GROUP BY book.title
ORDER BY COUNT(*) DESC
LIMIT 3;
```

1. `FROM rental JOIN book ON ...` → 대여 기록마다 책 제목을 붙인 표를 만든다
2. `GROUP BY book.title` → 제목이 같은 줄끼리 더미를 나눈다
3. `COUNT(*)` → 더미마다 센다
4. `ORDER BY COUNT(*) DESC` → 많은 순으로 정렬
5. `LIMIT 3` → 위에서 3개만

### 가장 어려웠던 부분과 해결 방법

> 아래는 [연습 기록](practice.md)을 바탕으로 한 초안입니다. 평가 전에 **내 말로** 다시 정리합니다.

| 어려웠던 것 | 막힌 지점 | 해결한 방법 |
|---|---|---|
| JOIN | SELECT가 맨 앞인데 어떻게 JOIN 결과에서 칸을 고르는지, `FROM rental`인데 `member.name`을 어떻게 쓰는지 | **쓰는 순서와 실행 순서가 다르다**는 걸 알고, FROM과 JOIN이 함께 "재료 표"를 만든다는 그림으로 이해 |
| LEFT JOIN 방향 | "LEFT JOIN이면 짝 없는 건 다 남는다"고 생각해서 오답 | "**FROM에 쓴 표만** 전부 남는다"를 왼쪽, 오른쪽을 바꾼 두 그림으로 비교 |
| GROUP BY | COUNT, SUM, AVG를 한 번에 배울 때 이해 못함 | COUNT 하나만, **카드를 더미로 나눠 세는** 그림으로 다시 배움 |
| FK와 DELETE | 왜 부모를 못 지우는지 | 부모와 자식을 **선으로 연결한 그림**("선이 붙은 부모는 못 지운다") |
| 서브쿼리 | 아직 진행 중 | 구현을 마친 뒤 완성된 쿼리에서 다시 검토 예정 |
