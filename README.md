# B6-1 · 정보를 깔끔하게 정리하는 디지털 서랍장 만들기

| 분야 | 구분 | 학습시간 | 필수/선택 |
|---|---|---|---|
| AI/SW 기초 | 데이터베이스와 백엔드 | 40시간 | 필수 |

**주제: 도서 대여 / DB: SQLite / 범위: 필수 요구사항만 (보너스 제외)**

> **평가하시는 분은 [실행과 확인 흐름](#실행과-확인-흐름)을 1단계부터 순서대로 따라 하면 됩니다.** 레포 받기부터 쿼리 15개 결과까지 이 문서만으로 재현됩니다.

| 문서 | 내용 |
|---|---|
| README.md (이 문서) | 실행과 확인 흐름, 과제 순서(1~8)별 구현 위치 |
| [docs/evaluation.md](docs/evaluation.md) | 평가 시연 순서, 평가 항목별 답과 보여줄 곳 |
| [results/results.md](results/results.md) | 쿼리 15개의 실제 실행 결과 |
| [docs/concepts.md](docs/concepts.md) | 과제 목표 6개 개념 정리 (그림 포함) |
| [docs/practice.md](docs/practice.md) | 확인 문제와 내 답, 헷갈렸던 질문, 구현 검토 기록 |

## 진행 상황

| 단계 | 할 일 | 파일 | 상태 |
|---|---|---|---|
| A. 스키마 | 테이블 4개의 칸, 타입, PK/FK, NOT NULL/UNIQUE | `sql/01_schema.sql` | ✅ |
| B. 샘플 데이터 | 테이블마다 10행 이상, 쿼리 결과가 의미 있게 섞기 | `sql/02_data.sql` | ✅ |
| C. 쿼리 15개 | 조회 4, 조인 4, 집계 3, 서브쿼리 1, 수정/삭제 2, 인덱스 1 | `sql/03_queries.sql` | ✅ |
| D. 실행 결과 | 쿼리마다 결과 저장 | `results/results.md` | ✅ |
| E. 개념 복습 | 평가 직전 마지막으로 개념 복습 (서브쿼리 Q12 포함) | `docs/concepts.md` | ⬜ 평가 직전 |

---

## 실행과 확인 흐름

**구조를 만들고 확인 → 데이터를 넣고 확인 → 규칙이 막는지 확인 → 쿼리 실행** 순서입니다.
쿼리 Q13, Q14가 데이터를 **바꾸기** 때문에 쿼리는 맨 마지막에 실행합니다. (먼저 실행하면 4단계의 "회원 10명"이 9명으로 보임)

![실행 흐름](docs/images/run_flow.svg)

**어디에 입력하나요?**

| 표시 | 어디 | 언제 |
|---|---|---|
| `$` | 터미널 | 1단계, 2단계의 앞부분 |
| `sqlite>` | `sqlite3 library.db`를 실행한 뒤 나오는 SQLite 화면 | 2단계 뒷부분부터 7단계까지 |

- `sqlite>`에서 **점(`.`)으로 시작하는 명령**(`.read`, `.tables` 등)은 SQL이 아니라 sqlite3 프로그램의 명령입니다. 세미콜론을 붙이지 않고, **같은 줄에 주석을 붙이면 안 됩니다.**
- SQL 문장(`SELECT ...;`, `PRAGMA ...;`)은 세미콜론(`;`)으로 끝냅니다.
- 1~7단계는 **한 번 연 `sqlite>`를 닫지 않고 이어서** 진행합니다.

### 1단계. 레포 받기

**무엇을**: GitHub의 레포를 내 컴퓨터에 받고, 그 폴더로 이동합니다.
**왜**: 이후 `.read sql/01_schema.sql` 같은 명령이 **지금 있는 폴더 기준**으로 파일을 찾기 때문입니다.

```bash
git clone https://github.com/codewhite7777/codyssey_b6-1.git
cd codyssey_b6-1
ls
```

**결과**: `README.md  docs  results  sql`이 보이면 됩니다. 이미 받아 둔 레포가 있으면 그 폴더에서 `git pull`만 합니다.

### 2단계. DB 열고 출력 설정하기

**무엇을**: 빈 DB 파일을 새로 열고, 결과가 보기 좋게 나오도록 설정합니다.
**왜**: 이전에 실행한 DB가 남아 있으면 쿼리가 바꾼 데이터가 섞이므로 지우고 새로 시작합니다. 그리고 SQLite는 **FK 검사가 기본으로 꺼져 있어서** 직접 켜야 합니다.

터미널(`$`)에서:

```bash
sqlite3 --version
rm -f library.db
sqlite3 library.db
```

`sqlite>`가 나오면 아래를 한 줄씩 입력합니다.

```sql
PRAGMA foreign_keys = ON;
.headers on
.mode table
.nullvalue NULL
```

| 명령 | 하는 일 |
|---|---|
| `sqlite3 --version` | SQLite가 설치돼 있는지 확인 (macOS 기본 설치, `3.xx` 숫자가 나오면 OK) |
| `rm -f library.db` | 이전에 만든 DB 파일 삭제 (없으면 아무 일도 안 함) |
| `sqlite3 library.db` | `library.db`를 열고 `sqlite>` 화면으로 들어감. 파일이 없으면 새로 만듦 |
| `PRAGMA foreign_keys = ON;` | **FK 검사 켜기.** 꺼져 있으면 5단계의 "없는 회원 참조"가 막히지 않음 |
| `.headers on` | 결과 맨 위에 칸 이름 표시 |
| `.mode table` | 결과를 테두리 있는 표로 출력 (오래된 SQLite에서 에러가 나면 `.mode column`) |
| `.nullvalue NULL` | NULL을 빈칸 대신 `NULL` 글자로 표시 (LEFT JOIN 결과를 보기 위해) |

**결과**: 아무것도 출력되지 않으면 정상입니다.

### 3단계. 스키마 만들고 구조 확인하기

**무엇을**: 테이블 4개를 만들고, PK, FK, NOT NULL, UNIQUE가 설계대로 들어갔는지 DB에 직접 물어봅니다.
**왜**: [4-2 스키마 그림](#4-2-데이터-모델스키마-설계)은 설계이고, 실제로 그렇게 만들어졌는지는 DB에서 확인해야 하기 때문입니다.

```sql
.read sql/01_schema.sql
.tables
PRAGMA table_info(rental);
PRAGMA foreign_key_list(rental);
PRAGMA foreign_key_list(book);
PRAGMA index_list(member);
```

| 명령 | 확인하는 것 |
|---|---|
| `.read sql/01_schema.sql` | 파일 안의 SQL을 위에서부터 실행 → 기존 테이블을 지우고(DROP) 4개를 새로 만듦 |
| `.tables` | 테이블 목록 (SQLite 전용) |
| `PRAGMA table_info(rental);` | 칸마다 타입, NOT NULL 여부, PK 여부 (SQLite 전용) |
| `PRAGMA foreign_key_list(rental);` | rental의 FK가 어느 테이블의 어느 칸을 가리키는지 (SQLite 전용) |
| `PRAGMA foreign_key_list(book);` | book의 FK (SQLite 전용) |
| `PRAGMA index_list(member);` | UNIQUE가 걸렸는지. UNIQUE를 걸면 DB가 자동으로 인덱스를 만듦 (SQLite 전용) |

**결과** (실제 출력)

```text
book      category  member    rental
```

```text
+-----+-------------+---------+---------+------------+----+
| cid |    name     |  type   | notnull | dflt_value | pk |
+-----+-------------+---------+---------+------------+----+
| 0   | id          | INTEGER | 0       | NULL       | 1  |
| 1   | member_id   | INTEGER | 1       | NULL       | 0  |
| 2   | book_id     | INTEGER | 1       | NULL       | 0  |
| 3   | rented_at   | DATE    | 1       | NULL       | 0  |
| 4   | returned_at | DATE    | 0       | NULL       | 0  |
+-----+-------------+---------+---------+------------+----+
```

```text
+----+-----+--------+-----------+----+-----------+-----------+-------+
| id | seq | table  |   from    | to | on_update | on_delete | match |
+----+-----+--------+-----------+----+-----------+-----------+-------+
| 0  | 0   | book   | book_id   | id | NO ACTION | NO ACTION | NONE  |
| 1  | 0   | member | member_id | id | NO ACTION | NO ACTION | NONE  |
+----+-----+--------+-----------+----+-----------+-----------+-------+
+----+-----+----------+-------------+----+-----------+-----------+-------+
| id | seq |  table   |    from     | to | on_update | on_delete | match |
+----+-----+----------+-------------+----+-----------+-----------+-------+
| 0  | 0   | category | category_id | id | NO ACTION | NO ACTION | NONE  |
+----+-----+----------+-------------+----+-----------+-----------+-------+
```

```text
+-----+---------------------------+--------+--------+---------+
| seq |           name            | unique | origin | partial |
+-----+---------------------------+--------+--------+---------+
| 0   | sqlite_autoindex_member_1 | 1      | u      | 0       |
+-----+---------------------------+--------+--------+---------+
```

**결과 읽는 법**

| 출력 | 읽는 법 | 확인된 것 |
|---|---|---|
| `.tables` | 테이블 이름 4개 | 테이블 4개 |
| `table_info` | `pk` 1 = PK, `notnull` 1 = NOT NULL | `id`가 PK, `returned_at`만 NULL 허용 (NULL = 대여 중) |
| `foreign_key_list` | `from` 칸이 `table`의 `to` 칸을 가리킴 | `rental.book_id → book.id`, `rental.member_id → member.id`, `book.category_id → category.id` (FK 3개 = 1:N 3개) |
| `index_list` | `unique` 1, `origin` u = UNIQUE로 생긴 인덱스 | member에 UNIQUE 있음 (`email`) |

- PK인 `id`의 `notnull`이 0으로 나오지만, `INTEGER PRIMARY KEY`는 비워서 넣으면 DB가 번호를 자동으로 채워서 실제로 비어 있을 수 없습니다.
- 다른 테이블도 `PRAGMA table_info(book);`처럼 이름만 바꿔 확인할 수 있습니다.

### 4단계. 샘플 데이터 넣고 행 수 확인하기

**무엇을**: 샘플 데이터를 넣고, 테이블마다 몇 행인지 셉니다.
**왜**: 과제 요구가 "각 테이블 10행 이상"이기 때문입니다.

```sql
.read sql/02_data.sql
SELECT (SELECT COUNT(*) FROM category) AS category, (SELECT COUNT(*) FROM member) AS member, (SELECT COUNT(*) FROM book) AS book, (SELECT COUNT(*) FROM rental) AS rental;
```

**결과** (실제 출력)

```text
+----------+--------+------+--------+
| category | member | book | rental |
+----------+--------+------+--------+
| 10       | 10     | 12   | 15     |
+----------+--------+------+--------+
```

두 번째 줄은 네 테이블의 `COUNT(*)`를 한 줄로 보려고 묶은 것입니다. `SELECT COUNT(*) FROM member;`처럼 하나씩 실행해도 같습니다.

### 5단계. 제약조건이 막는지 확인하기

**무엇을**: 규칙을 어기는 데이터를 일부러 넣어 봅니다. **세 줄 모두 에러가 나야 정상**입니다.
**왜**: 과제 요구가 "NOT NULL, UNIQUE 적용"과 "없는 값 참조가 실제로 막혀야 한다"이기 때문입니다.

```sql
INSERT INTO member (id, name, email) VALUES (99, NULL, 'x@example.com');
INSERT INTO member (id, name, email) VALUES (99, '홍길동', 'member01@example.com');
INSERT INTO rental (id, member_id, book_id, rented_at) VALUES (99, 999, 1, '2026-10-14');
```

**결과** (실제 출력)

```text
Runtime error: NOT NULL constraint failed: member.name (19)
Runtime error: UNIQUE constraint failed: member.email (19)
Runtime error: FOREIGN KEY constraint failed (19)
```

SQLite 버전에 따라 앞부분이 `Error:`나 `Runtime error near line ...:`로 나올 수 있습니다. **`... constraint failed`가 보이면 막힌 것**입니다.

| 줄 | 넣으려던 것 | 막은 규칙 |
|---|---|---|
| 1 | 이름 없는 회원 | `member.name` NOT NULL |
| 2 | 이미 있는 이메일 `member01@example.com` | `member.email` UNIQUE |
| 3 | 없는 회원 999번의 대여 기록 | `rental.member_id → member.id` FK |

정말 저장되지 않았는지도 확인합니다.

```sql
SELECT COUNT(*) FROM member WHERE id = 99;
SELECT COUNT(*) FROM rental WHERE id = 99;
```

**결과**: 둘 다 `0`. 막힌 INSERT는 저장되지 않았습니다.

### 6단계. 쿼리 15개 실행하기

**무엇을**: 쿼리 15개를 실행하고 결과 표를 봅니다.
**왜**: 과제의 핵심 쿼리 15개(조회 4, 조인 4, 집계 3, 서브쿼리 1, 수정/삭제 2, 인덱스 1)와 실행 결과를 확인하기 위해서입니다.

```sql
.echo on
.read sql/03_queries.sql
```

| 명령 | 하는 일 |
|---|---|
| `.echo on` | 실행하는 SQL을 결과 위에 같이 출력. `-- Q01. [기본 조회] ...` 설명 줄도 나와서 **어떤 표가 몇 번 쿼리인지** 알 수 있음 |
| `.read sql/03_queries.sql` | Q01부터 Q15까지 차례로 실행 |

**결과**: 화면에 `-- Q01. ...` 설명, SQL, 결과 표가 Q15까지 차례로 나옵니다. 결과는 [results/results.md](results/results.md)와 같아야 합니다.

- **값은 같아도 줄 순서가 다를 수 있습니다.** 같은 카테고리 안의 책 순서(Q06, Q08)나 동점끼리의 순서(Q09, Q11)는 `ORDER BY`로 정하지 않아서, SQLite 버전에 따라 results.md와 순서만 다르게 나올 수 있습니다.
- Q13(UPDATE), Q14(DELETE), Q15(CREATE INDEX)는 결과 표가 없습니다. 바로 아래의 **확인용 SELECT/PRAGMA**(15개에 세지 않음)가 바뀐 결과를 보여줍니다.
- 쿼리 하나만 다시 보고 싶으면 `sql/03_queries.sql`에서 그 SQL을 복사해 `sqlite>`에 붙여넣습니다. 단, Q13, Q14 실행 뒤에는 데이터가 바뀌어 있습니다 (예: 한서윤 삭제). 처음 상태로 보려면 7단계 후 2단계부터 다시 합니다.

### 7단계. 끝내기

```sql
.quit
```

`sqlite>`를 끝내고 터미널로 돌아갑니다. `library.db` 파일은 SQL 파일로 언제든 다시 만들 수 있어서 레포에 올리지 않습니다 (`.gitignore`).

---

## 1. 미션 소개

도서관에서 **회원이 책을 빌리고 반납하는 기록**을 DB로 관리합니다.
백엔드 프레임워크 없이 SQL만으로 **데이터 모델링 → 데이터 입력 → 요구사항을 SQL로 해결**하는 흐름을 완성합니다.

## 2. 최종 결과물

| 과제 요구 | 파일 | 상태 |
|---|---|---|
| 도메인 DB 1개 (테이블 4개 이상, 1:N 2개 이상) | 도서 대여 DB: 테이블 4개, 1:N 3개 | ✅ |
| 스키마 생성 스크립트 1개 | [sql/01_schema.sql](sql/01_schema.sql) | ✅ |
| 샘플 데이터 입력 스크립트 1개 (테이블당 10행 이상) | [sql/02_data.sql](sql/02_data.sql) | ✅ |
| 핵심 쿼리 15개 | [sql/03_queries.sql](sql/03_queries.sql) | ✅ |
| 실행 결과 캡처 폴더 | [results/results.md](results/results.md) | ✅ |
| (선택) ERD | 아래 구현 구조 그림, [4-2](#4-2-데이터-모델스키마-설계)의 스키마 그림 | ✅ |

**구현 구조**: SQL 파일 3개가 `library.db` 안에 테이블 4개를 만들고 데이터를 넣은 뒤, 쿼리 15개의 결과를 `results/results.md`에 남깁니다.

![구현 구조](docs/images/implementation.svg)

```text
codyssey_b6-1/
├── README.md            실행과 확인 흐름, 과제 순서별 구현 위치
├── sql/
│   ├── 01_schema.sql    CREATE TABLE (부모 → 자식 순서)
│   ├── 02_data.sql      INSERT (부모 → 자식 순서)
│   └── 03_queries.sql   핵심 쿼리 15개
├── results/
│   └── results.md       쿼리 실행 결과
└── docs/
    ├── evaluation.md    평가 준비
    ├── concepts.md      개념 정리
    ├── practice.md      연습과 검토 기록
    └── images/          그림
```

## 3. 과제 목표

| 과제 목표 | 개념 정리 | 구현에서 확인할 곳 |
|---|---|---|
| 1. DB가 엑셀과 뭐가 다른지, 왜 테이블로 나누는지 | [개념 1](docs/concepts.md#1-db는-엑셀과-뭐가-다른가-왜-테이블로-나눠-저장하나) | [5단계 제약조건 확인](#5단계-제약조건이-막는지-확인하기) |
| 2. PK/FK와 1:N 관계 | [개념 2](docs/concepts.md#2-pk--fk--1n-관계는-데이터를-어떻게-연결하나) | [4-2 스키마](#4-2-데이터-모델스키마-설계), [3단계 구조 확인](#3단계-스키마-만들고-구조-확인하기) |
| 3. SELECT / INSERT / UPDATE / DELETE 구분 | [개념 3](docs/concepts.md#3-select--insert--update--delete는-언제-쓰나) | `02_data.sql`(INSERT), Q01~Q12(SELECT), Q13(UPDATE), Q14(DELETE) |
| 4. JOIN과 GROUP BY | [개념 4](docs/concepts.md#4-join과-group-by로-연결된-데이터를-한-번에-뽑는-방법) | Q05~Q08(JOIN), Q09~Q11(GROUP BY) |
| 5. 검색 / 정렬 / 집계 / 랭킹 | [개념 5](docs/concepts.md#5-검색--정렬--집계--랭킹을-sql로-어떻게-푸나) | Q01~Q04, Q09~Q11, Q12 |
| 6. 인덱스가 왜 필요한지, 어디에 거는지 | [개념 6](docs/concepts.md#6-인덱스는-왜-필요하고-어디에-거나) | Q15 |

## 4. 기능 요구 사항

### 4-1. DB 환경 준비

| 요구 | 선택 | 이유 |
|---|---|---|
| 로컬 DB 1개 | SQLite | macOS에 기본 설치, 파일 하나가 DB라 서버 실행이 필요 없음 |
| SQL 실행 도구 | 터미널 CLI (`sqlite3`) | 별도 설치 없이 바로 실행, 결과를 텍스트로 확인하기 쉬움 |

실행 방법은 [실행과 확인 흐름](#실행과-확인-흐름) 1~2단계에 있습니다. DB 전용 문법(`PRAGMA` 등)은 SQL 파일과 이 문서에 "SQLite 전용"으로 표시했습니다.

### 4-2. 데이터 모델(스키마) 설계

![스키마](docs/images/schema.svg)

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

**DB에서 직접 확인**: [3단계](#3단계-스키마-만들고-구조-확인하기)

### 4-3. 제약조건 적용

| 요구 | 적용한 곳 |
|---|---|
| NOT NULL 1개 이상 | `category.name`, `member.name`, `member.email`, `book`의 칸 전부, `rental`에서 `returned_at`을 뺀 칸 |
| UNIQUE 1개 이상 | `member.email`, `category.name` |
| FK가 실제로 동작 | `PRAGMA foreign_keys = ON` + `REFERENCES` 3개 |

**막히는지 확인**: [5단계](#5단계-제약조건이-막는지-확인하기)

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
| 책이 한 권도 없는 카테고리 | 시집, 요리 | Q06과 Q08 비교 |
| 한 번도 안 빌린 회원 | 박민수, 한서윤 | Q07, Q12 |
| 한 번도 안 빌린 책 | 국부론, 하루 한 줄 에세이 | Q11 순위에 없음 |
| 아직 반납 안 한 대여 | rental 12~15 | Q05, Q13 |
| 많이 빌린 회원과 책 | 김철수 4회, 해리포터와 마법사의 돌 4회 | Q09, Q11 |
| 가격 5,000 ~ 25,000원 | book 전체 | Q01, Q03, Q10 |
| 제목에 같은 단어 | "해리포터" 2권 | Q02 |
| 대여일 9월 ~ 10월 | rental 전체 | Q04 |
| 전화번호 없는 회원 | 임도현, 오지훈 | phone NULL 허용 |

**행 수 확인**: [4단계](#4단계-샘플-데이터-넣고-행-수-확인하기)

### 4-5. 핵심 SQL 쿼리 15개

[sql/03_queries.sql](sql/03_queries.sql)에 쿼리마다 "무엇을 확인하는지" 한 줄 설명을 붙였습니다.

| 범주 | 필요 개수 | 쿼리 | 무엇을 확인하나 | 결과 |
|---|---|---|---|---|
| 기본 조회 | 4개 이상 | Q01 | 15,000원 이상인 책, 비싼 순 (WHERE, ORDER BY) | 8줄 |
| | | Q02 | 제목에 "해리포터"가 들어간 책 (LIKE) | 2줄 |
| | | Q03 | 가장 비싼 책 TOP 3 (ORDER BY, LIMIT) | 3줄 |
| | | Q04 | 최근 30일 대여 기록, 최신순 | 10줄 |
| 조인 | 4개 이상 (INNER 2, LEFT 1 이상) | Q05 | INNER: 대여 중인 책 목록 | 4줄 |
| | | Q06 | INNER: 카테고리별 책 (책 있는 카테고리만) | 12줄 |
| | | Q07 | LEFT: 대여 기록 없는 회원도 포함한 회원별 대여 번호 | 17줄 (NULL 2) |
| | | Q08 | LEFT: 책 없는 카테고리도 포함한 카테고리별 책 (Q06과 LEFT 한 단어만 다름) | 14줄 (NULL 2) |
| 집계 | 3개 이상 (COUNT, SUM, AVG 중 2개 이상) | Q09 | 회원별 대여 횟수, 많은 순 (COUNT) | 8줄 |
| | | Q10 | 카테고리별 책 수, 가격 합계, 평균 (COUNT, SUM, AVG) | 8줄 |
| | | Q11 | 가장 많이 대여된 책 TOP 3 | 3줄 |
| 서브쿼리 | 1개 이상 | Q12 | 대여 기록이 없는 회원 (NOT IN) | 2줄 |
| 수정 및 삭제 | 2개 이상 | Q13 | UPDATE: 15번 대여 반납 처리 | 1줄 변경 |
| | | Q14 | DELETE: 대여 기록 없는 회원 한서윤 삭제 | 1줄 삭제 |
| 인덱스 | 1개 이상 | Q15 | `rental.member_id`에 인덱스 + 이유 | 생성 |

- 날짜 기준일은 `2026-10-14`로 고정했습니다. "오늘"을 구하는 함수는 DB 전용 문법이고 실행하는 날마다 결과가 바뀌기 때문입니다.
- UPDATE, DELETE, CREATE INDEX 뒤에는 바뀐 걸 보여주는 **확인용 SELECT/PRAGMA**를 붙였습니다 (15개에 세지 않음).
- 읽기(Q01~Q12)를 먼저, 바꾸기(Q13~Q14)를 나중에 둬서 결과가 섞이지 않게 했습니다.

**실행**: [6단계](#6단계-쿼리-15개-실행하기)

### 4-6. 결과 확인 자료

[results/results.md](results/results.md)에 쿼리 15개와 확인용 SELECT/PRAGMA의 결과를 sqlite3로 실행한 출력 그대로 SQL과 함께 저장했습니다.

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

| 과제 예시 | 이 DB의 쿼리 |
|---|---|
| 대여 중인 책 목록 | Q05 (`returned_at`이 NULL인 대여 + 책 제목) |
| 회원별 대여 횟수 집계 | Q09 |
| 최근 30일 대여 기록 | Q04 |
| 연체 상태로 업데이트 | Q13. 이 설계에는 상태 칸이 없어 **반납 처리**(`returned_at` 채우기)로 대신함 |
| 대여 기록이 없는 회원 찾기 (서브쿼리) | Q12 |
