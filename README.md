# B6-1 · 정보를 깔끔하게 정리하는 디지털 서랍장 만들기

| 분야 | 구분 | 학습시간 | 필수/선택 |
|---|---|---|---|
| AI/SW 기초 | 데이터베이스와 백엔드 | 40시간 | 필수 |

**주제: 도서 대여 / DB: SQLite / 범위: 필수 요구사항만 (보너스 제외)**

이 README는 과제 문서의 순서(1~8)대로 **무엇을 어디에 구현했고, 어떻게 확인하는지**를 정리합니다. 개념 설명은 따로 분리했습니다.

| 문서 | 내용 |
|---|---|
| README.md (이 문서) | 과제 순서, 요구사항별 구현 위치와 확인 방법 |
| [docs/concepts.md](docs/concepts.md) | 과제 목표 6개 개념 정리 (그림 포함) |
| [docs/practice.md](docs/practice.md) | 확인 문제와 내 답, 헷갈렸던 질문, 구현 검토 기록 |
| [docs/evaluation.md](docs/evaluation.md) | 피어 평가 항목별 답과 보여줄 곳 |

## 진행 상황

초안을 만들고, 줄마다 "왜 이렇게 썼나"를 묻고 답하며 검토합니다. 검토 내용은 [docs/practice.md](docs/practice.md)에 남깁니다.

| 단계 | 할 일 | 파일 | 상태 |
|---|---|---|---|
| A. 스키마 | 테이블 4개의 칸, 타입, PK/FK, NOT NULL/UNIQUE | `sql/01_schema.sql` | ✅ |
| B. 샘플 데이터 | 테이블마다 10행 이상, 쿼리 결과가 의미 있게 섞기 | `sql/02_data.sql` | ✅ |
| C. 쿼리 15개 | 조회 4, 조인 4, 집계 3, 서브쿼리 1, 수정/삭제 2, 인덱스 1 | `sql/03_queries.sql` | 🔍 초안 검토 중 |
| D. 실행 결과 | 쿼리마다 결과 저장 | `results/` | ⬜ |
| E. 복습 | 완성된 쿼리로 전체 개념 복습, 서브쿼리 재검토 | `docs/concepts.md` | ⬜ |

---

## 1. 미션 소개

도서관에서 **회원이 책을 빌리고 반납하는 기록**을 DB로 관리합니다.
백엔드 프레임워크 없이 SQL만으로 **데이터 모델링 → 데이터 입력 → 요구사항을 SQL로 해결**하는 흐름을 완성합니다.

## 2. 최종 결과물

| 과제 요구 | 파일 | 상태 |
|---|---|---|
| 도메인 DB 1개 (테이블 4개 이상, 1:N 2개 이상) | 도서 대여 DB: 테이블 4개, 1:N 3개 | ✅ |
| 스키마 생성 스크립트 1개 | [sql/01_schema.sql](sql/01_schema.sql) | ✅ |
| 샘플 데이터 입력 스크립트 1개 (테이블당 10행 이상) | [sql/02_data.sql](sql/02_data.sql) | ✅ 검토 완료 |
| 핵심 쿼리 15개 | [sql/03_queries.sql](sql/03_queries.sql) | 🔍 초안 검토 중 |
| 실행 결과 캡처 폴더 | [results/](results/) | ⬜ |
| (선택) ERD | [4-2](#4-2-데이터-모델스키마-설계)의 텍스트 관계도로 대체 | ✅ |

```text
codyssey_B6-1/
├── README.md            과제 순서와 요구사항별 확인 방법
├── sql/
│   ├── 01_schema.sql    CREATE TABLE (부모 → 자식 순서)
│   ├── 02_data.sql      INSERT (부모 → 자식 순서)
│   └── 03_queries.sql   핵심 쿼리 15개
├── results/             쿼리 실행 결과
└── docs/
    ├── concepts.md      개념 정리
    ├── practice.md      연습과 검토 기록
    ├── evaluation.md    피어 평가 준비
    └── images/          그림
```

## 3. 과제 목표

목표마다 개념은 concepts.md에, 실제로 쓰인 곳은 이 레포의 SQL 파일에서 확인합니다.

| 과제 목표 | 개념 정리 | 구현에서 확인할 곳 |
|---|---|---|
| 1. DB가 엑셀과 뭐가 다른지, 왜 테이블로 나누는지 | [개념 1](docs/concepts.md#1-db는-엑셀과-뭐가-다른가-왜-테이블로-나눠-저장하나) | [4-3 제약조건](#4-3-제약조건-적용) |
| 2. PK/FK와 1:N 관계 | [개념 2](docs/concepts.md#2-pk--fk--1n-관계는-데이터를-어떻게-연결하나) | [4-2 관계도](#4-2-데이터-모델스키마-설계), `01_schema.sql` |
| 3. SELECT / INSERT / UPDATE / DELETE 구분 | [개념 3](docs/concepts.md#3-select--insert--update--delete는-언제-쓰나) | `02_data.sql`, `03_queries.sql` 수정/삭제 |
| 4. JOIN과 GROUP BY | [개념 4](docs/concepts.md#4-join과-group-by로-연결된-데이터를-한-번에-뽑는-방법) | `03_queries.sql` 조인, 집계 |
| 5. 검색 / 정렬 / 집계 / 랭킹 | [개념 5](docs/concepts.md#5-검색--정렬--집계--랭킹을-sql로-어떻게-푸나) | `03_queries.sql` 기본 조회, 집계, 서브쿼리 |
| 6. 인덱스가 왜 필요한지, 어디에 거는지 | [개념 6](docs/concepts.md#6-인덱스는-왜-필요하고-어디에-거나) | `03_queries.sql` 인덱스 |

## 4. 기능 요구 사항

### 4-1. DB 환경 준비

| 요구 | 선택 | 이유 |
|---|---|---|
| 로컬 DB 1개 | SQLite | macOS에 기본 설치, 파일 하나가 DB라 서버 실행이 필요 없음 |
| SQL 실행 도구 | 터미널 CLI (`sqlite3`) | 별도 설치 없이 바로 실행, 결과를 텍스트로 저장하기 쉬움 |

**실행 방법**

```bash
sqlite3 library.db
```

```sql
PRAGMA foreign_keys = ON;   -- SQLite 전용. 접속할 때마다 켜야 FK 검사가 동작함
.mode table                 -- 결과를 표 모양으로 (점으로 시작하는 건 SQLite 프로그램 명령)
.headers on
.read sql/01_schema.sql
.read sql/02_data.sql
.read sql/03_queries.sql
.quit
```

- `01_schema.sql`은 맨 앞에서 기존 테이블을 지우고(`DROP TABLE IF EXISTS`) 새로 만들어서 **몇 번이든 다시 실행**할 수 있습니다.
- `library.db`는 SQL 파일로 언제든 다시 만들 수 있어 레포에 올리지 않습니다 (`.gitignore`).
- DB 전용 문법(`PRAGMA` 등)은 SQL 파일에 주석으로 표시했습니다.

### 4-2. 데이터 모델(스키마) 설계

```text
category (1) ──< book   (N)     카테고리 1개에 책 여러 권      book.category_id → category.id
book     (1) ──< rental (N)     책 1권은 여러 번 대여됨         rental.book_id   → book.id
member   (1) ──< rental (N)     회원 1명은 여러 번 대여함       rental.member_id → member.id
```

`<`가 붙은 쪽이 여러 개(N) 쪽이고 FK를 가진 테이블입니다.

| 테이블 | 칸 (타입) | 제약조건 |
|---|---|---|
| category | id (INTEGER), name (TEXT) | PK, name NOT NULL UNIQUE |
| member | id (INTEGER), name (TEXT), email (TEXT), phone (TEXT) | PK, name NOT NULL, email NOT NULL UNIQUE |
| book | id (INTEGER), title (TEXT), category_id (INTEGER), price (INTEGER) | PK, FK, 모두 NOT NULL |
| rental | id (INTEGER), member_id (INTEGER), book_id (INTEGER), rented_at (DATE), returned_at (DATE) | PK, FK 2개, returned_at만 NULL 허용 (NULL = 대여 중) |

| 요구 | 충족 |
|---|---|
| 테이블 4개 이상 | ✅ 4개 |
| 각 테이블에 PK | ✅ |
| FK로 1:N 관계 2개 이상 | ✅ 3개 |
| 컬럼 타입을 의미에 맞게 | ✅ 글자 TEXT, 숫자 INTEGER, 날짜 DATE (`book.price`는 정렬, 비교, SUM/AVG를 위해 INTEGER) |
| 이름이 역할을 드러내게 | ✅ `member_id`, `rented_at`, `returned_at` 등 |

### 4-3. 제약조건 적용

아래 SQL은 모두 **막혀야 정상**입니다. 스키마와 데이터를 넣은 뒤 실행해서 확인합니다.

| 요구 | 적용한 곳 | 확인 SQL | 기대 결과 |
|---|---|---|---|
| NOT NULL 1개 이상 | `member.name`, `book.title` 등 | `INSERT INTO member (id, name, email) VALUES (99, NULL, 'x@example.com');` | `NOT NULL constraint failed` |
| UNIQUE 1개 이상 | `member.email`, `category.name` | `INSERT INTO member (id, name, email) VALUES (99, '홍길동', 'member01@example.com');` | `UNIQUE constraint failed` |
| FK가 실제로 동작 | `PRAGMA foreign_keys = ON` + `REFERENCES` | `INSERT INTO rental (id, member_id, book_id, rented_at) VALUES (99, 999, 1, '2026-10-14');` | `FOREIGN KEY constraint failed` |

### 4-4. 샘플 데이터 준비

| 테이블 | 행 수 | 넣는 순서 |
|---|---|---|
| category | 10 | 1 (부모) |
| member | 10 | 2 (부모) |
| book | 12 | 3 (category의 자식) |
| rental | 15 | 4 (member, book의 자식) |

쿼리 결과가 "아무것도 안 나옴"이나 "전부 나옴"이 되지 않도록 **일부러 섞은 데이터**입니다.

| 섞은 데이터 | 어떤 행 | 확인할 쿼리 |
|---|---|---|
| 책이 한 권도 없는 카테고리 | 시집, 요리 | category LEFT JOIN book |
| 한 번도 안 빌린 회원 | 박민수, 한서윤 | member LEFT JOIN rental, 서브쿼리 |
| 한 번도 안 빌린 책 | 국부론, 하루 한 줄 에세이 | book LEFT JOIN rental |
| 아직 반납 안 한 대여 | rental 12~15 | 대여 중 조회, UPDATE 반납 처리 |
| 많이 빌린 회원과 책 | 김철수 4회, 해리포터와 마법사의 돌 4회 | GROUP BY 인기 순위 |
| 가격 5,000 ~ 25,000원 | book 전체 | WHERE 범위, 정렬, SUM/AVG |
| 제목에 같은 단어 | "해리포터" 2권 | LIKE 검색 |
| 대여일 9월 ~ 10월 | rental 전체 | 날짜 정렬, 최근 대여 |
| 전화번호 없는 회원 | 임도현, 오지훈 | phone NULL 허용 |

### 4-5. 핵심 SQL 쿼리 15개

[sql/03_queries.sql](sql/03_queries.sql)에 쿼리마다 "무엇을 확인하는지" 한 줄 설명을 붙였습니다. (🔍 초안 검토 중)

| 범주 | 필요 개수 | 쿼리 | 무엇을 확인하나 | 결과 |
|---|---|---|---|---|
| 기본 조회 | 4개 이상 | Q01 | 15,000원 이상인 책, 비싼 순 (WHERE, ORDER BY) | 8줄 |
| | | Q02 | 제목에 "해리포터"가 들어간 책 (LIKE) | 2줄 |
| | | Q03 | 가장 비싼 책 TOP 3 (ORDER BY, LIMIT) | 3줄 |
| | | Q04 | 최근 30일 대여 기록, 최신순 | 10줄 |
| 조인 | 4개 이상 (INNER 2, LEFT 1 이상) | Q05 | INNER: 대여 중인 책 목록 | 4줄 |
| | | Q06 | INNER: 책마다 카테고리 이름 | 12줄 |
| | | Q07 | LEFT: 대여 기록 없는 회원도 포함한 회원별 대여 번호 | 17줄 (NULL 2) |
| | | Q08 | LEFT: 책 없는 카테고리도 포함한 카테고리별 책 | 14줄 (NULL 2) |
| 집계 | 3개 이상 (COUNT, SUM, AVG 중 2개 이상) | Q09 | 회원별 대여 횟수, 많은 순 (COUNT) | 8줄 |
| | | Q10 | 카테고리별 책 수, 가격 합계, 평균 (COUNT, SUM, AVG) | 8줄 |
| | | Q11 | 가장 많이 대여된 책 TOP 3 | 3줄 |
| 서브쿼리 | 1개 이상 | Q12 | 대여 기록이 없는 회원 (NOT IN) | 2줄 |
| 수정 및 삭제 | 2개 이상 | Q13 | UPDATE: 15번 대여 반납 처리 | 1줄 변경 |
| | | Q14 | DELETE: 대여 기록 없는 회원 한서윤 삭제 | 1줄 삭제 |
| 인덱스 | 1개 이상 | Q15 | `rental.member_id`에 인덱스 + 이유 | 생성 |

- 날짜 기준일은 `2026-10-14`로 고정했습니다. "오늘"을 구하는 함수는 DB 전용 문법이고 실행하는 날마다 결과가 바뀌기 때문입니다.
- UPDATE, DELETE 뒤에는 바뀐 걸 보여주는 **확인용 SELECT**를 붙였습니다 (15개에 세지 않음).
- 읽기(Q01~Q12)를 먼저, 바꾸기(Q13~Q14)를 나중에 둬서 결과가 섞이지 않게 했습니다.

### 4-6. 결과 확인 자료

D단계에서 쿼리마다 실행 결과를 `results/`에 저장합니다.

## 5. 보너스 과제

이번 범위에서는 하지 않습니다. 필수 요구사항에 집중합니다.

## 6. 개발 환경

| 항목 | 사용 |
|---|---|
| OS | macOS |
| DB | SQLite 3 (macOS 기본 설치) |
| 실행 도구 | 터미널 `sqlite3` CLI |

## 7. 제약 사항

| 제약 | 지킨 방법 |
|---|---|
| 백엔드 프레임워크 사용 금지 | SQL 파일 3개만 사용 |
| 로컬 DB만 사용 | SQLite 파일 DB |
| 뷰, 프로시저, 트리거 사용 금지 | 사용하지 않음 |
| 정규화를 과하게 파지 않기 | 테이블 4개, 관계가 자연스럽고 쿼리가 잘 나오는 구조 |

## 8. 결과 예시와 대응

과제의 쿼리 예시가 이 DB에서 어떤 쿼리가 될지 미리 정리합니다. C단계에서 구현합니다.

| 과제 예시 | 이 DB에서 | 쓰는 것 |
|---|---|---|
| 대여 중인 책 목록 | `returned_at`이 NULL인 대여 + 책 제목 | JOIN, IS NULL |
| 회원별 대여 횟수 집계 | 회원 이름별 COUNT | JOIN, GROUP BY |
| 최근 30일 대여 기록 | 기준일로부터 30일 안의 `rented_at` | WHERE, 날짜 비교 |
| 연체 상태로 업데이트 | 이 설계에는 상태 칸이 없어 **반납 처리**(`returned_at` 채우기)로 대신함 | UPDATE |
| 대여 기록이 없는 회원 찾기 | 박민수, 한서윤 | 서브쿼리 (NOT IN) |
