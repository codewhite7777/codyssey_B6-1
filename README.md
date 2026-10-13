# B6-1 · 정보를 깔끔하게 정리하는 디지털 서랍장 만들기

**주제: 카페 주문 관리 / DB: SQLite / 핵심 구현: SQL 파일 3개**

고객이 여러 번 주문하고, 한 주문에 여러 메뉴를 담는 관계를 데이터베이스로 표현합니다.
테이블 만들기 → 샘플 입력 → 조회·조인·집계 → 수정·삭제 → 결과 확인까지 수행합니다.
웹사이트나 API를 실행하는 과제가 아닙니다. SQLite에 SQL을 실행하여 결과 표를 확인합니다.

**먼저 볼 곳:** [실행 방법](#3-실행-방법) · [테이블과 관계](#4-테이블을-왜-이렇게-나눴는가) · [개념 설명](#5-이-프로젝트로-이해하는-핵심-개념) · [쿼리 15개 안내](#6-쿼리-15개를-읽는-순서) · [실제 결과](results/queries.txt) · [검증 기록](results/verification.txt)

## 1. 명세와 구현 범위

과제는 자유 주제와 DB 선택을 허용합니다. 이 구현에서는 관계가 익숙한 **카페 주문**, 별도 DB 서버가 필요 없는 **SQLite**를 선택했습니다. [SQLite 소개](https://sqlite.org/whentouse.html)

| 명세의 필수 조건 | 구현 위치와 확인 방법 |
|---|---|
| 최소 4개 테이블, 각 테이블 PK | `schema.sql`: customer, menu, cafe_order, order_item |
| FK를 이용한 1:N 관계 최소 2개 | FK 3개. 없는 고객·주문·메뉴 참조 및 부모 삭제 차단 검사 |
| 테이블별 최소 10행 | `seed.sql`: 고객 12 / 메뉴 10 / 주문 12 / 주문상세 24 |
| NOT NULL, UNIQUE | 이름·이메일 등 NOT NULL, 이메일·메뉴명 UNIQUE |
| 기본 조회 4개 | Q01~Q04: WHERE, LIKE, ORDER BY, LIMIT |
| 조인 4개 | Q05~Q07 INNER JOIN 3개, Q08 LEFT JOIN 1개 |
| 집계 3개 | Q09~Q11: GROUP BY와 COUNT, SUM, AVG |
| 서브쿼리 1개 | Q12: NOT EXISTS |
| 수정·삭제 2개 | Q13 UPDATE / Q14 DELETE, 변경 전후와 원복 결과 포함 |
| 인덱스 1개와 이유 | Q15: 주문 시각 인덱스 생성, 적용 컬럼·실행 계획 확인 |
| 각 쿼리 설명과 결과 | `queries.sql`의 Q번호별 주석 + `results/queries.txt` |
| 백엔드 프레임워크·뷰·프로시저·트리거 금지 | 사용하지 않음. ORM, API, 화면, Docker도 추가하지 않음 |

**쿼리 개수 해석:** 평가표의 분류 합계인 `4 + 4 + 3 + 1 + 2 + 1 = 15`를 Q01~Q15로 구성했습니다.
수정 전후를 보는 SELECT, 트랜잭션 제어, 인덱스 확인 명령은 보조 문장입니다. 이를 별도 필수 쿼리로 중복 계산하지 않습니다.

**선택 추가:** 재검증용 `verify.py` 하나와 이 README의 보너스 해설을 제공합니다.
Python은 서비스를 구현하지 않으며, SQL 직접 실행에는 필요하지 않습니다. 별도 라이브러리 설치도 없습니다.
ERD 이미지 파일은 선택 제출물이므로 추가하지 않고 아래에 관계도를 넣었습니다.

## 2. 파일과 구현 단계

```text
codyssey_B6-1/
├── README.md                 실행법, 설계 이유, 개념, 쿼리 해설, 평가 준비
├── schema.sql                1단계: 테이블과 PK/FK/제약조건 생성
├── seed.sql                  2단계: 부모 → 자식 순서의 샘플 INSERT
├── queries.sql               3단계: Q01~Q15 핵심 SQL과 확인용 문장
├── results/
│   ├── queries.txt           실제 SQL 원문과 실행 결과 표
│   └── verification.txt      기대값·제약조건·반복 실행 검사 기록
├── verify.py                 선택: 표준 라이브러리로 SQL을 재검증
└── .gitignore                생성된 DB·캐시를 Git에서 제외
```

| 단계 | 알아야 할 개념 | 구현 목표 | 완료 기준 |
|---|---|---|---|
| 1. 서랍 구조 설계 | 테이블, 행, 컬럼, PK, FK, 1:N | `schema.sql`로 4개 테이블 생성 | 각 PK 및 FK 3개 존재 |
| 2. 연결된 자료 입력 | INSERT, 부모·자식, 무결성 | `seed.sql`을 순서대로 실행 | 각 10행 이상, 없는 번호 참조 없음 |
| 3. 필요한 정보 조회 | WHERE, JOIN, GROUP BY, 서브쿼리 | Q01~Q12 실행 | 실제 결과가 샘플에서 계산한 값과 일치 |
| 4. 변경·검색 경로 확인 | UPDATE, DELETE, 트랜잭션, 인덱스 | Q13~Q15 실행 | 변경·삭제 확인 후 원복, 인덱스 생성 |
| 5. 검증·설명 | 오류 원인, 기대값, 실행 흐름 | 결과 기록과 README 확인 | 코드와 결과를 연결해 설명할 근거 확보 |

## 3. 실행 방법

### 3-1. 저장소 받기와 준비

터미널에서 실행합니다. 이후 모든 명령은 `codyssey_B6-1` 폴더 기준입니다.

```bash
git clone https://github.com/codewhite7777/codyssey_B6-1.git
cd codyssey_B6-1
sqlite3 --version
```

버전이 출력되면 SQLite CLI가 준비된 것입니다. CLI는 명령을 글자로 입력하는 도구입니다.
명령을 찾을 수 없다면 [SQLite 공식 다운로드](https://sqlite.org/download.html)에서 운영체제에 맞는 **sqlite-tools**를 준비하고 `sqlite3` 실행 파일의 위치를 PATH에 등록합니다.
macOS에서 Homebrew가 이미 설치되어 있다면 `brew install sqlite`로 설치할 수도 있습니다. [Homebrew 공식 안내](https://formulae.brew.sh/formula/sqlite)
Windows에서 실행 파일이 현재 폴더에 있다면 PowerShell에서 `sqlite3` 대신 `./sqlite3.exe`를 사용할 수 있습니다.

SQLite CLI를 설치하지 않고 **제출물 실행과 검사부터 확인하려면 3-5의 Python 검증 경로**를 사용합니다.
두 경로는 같은 SQL 파일을 실행하지만, CLI 경로는 `cafe.db`를 남기고 검증 경로는 임시 DB만 사용합니다.

### 3-2. 최초 1회: 파일 DB와 샘플 만들기

터미널에서 다음 명령으로 DB를 엽니다. 아직 파일이 없으면 새 DB를 만듭니다.

```bash
sqlite3 cafe.db
```

이제 `sqlite>`가 보이는 **SQLite 내부**에서 아래를 입력합니다. 프롬프트 글자 자체는 입력하지 않습니다.

```text
.bail on
.headers on
.mode column
.nullvalue NULL
.read schema.sql
.read seed.sql
.tables
```

`.read`는 SQL 파일을 읽어 실행하는 **SQLite CLI 명령**입니다. SQL 문법이 아니므로 SQL 파일에 넣지 않았습니다.
점으로 시작하는 CLI 명령은 위처럼 한 줄씩 입력하고 세미콜론을 붙이지 않습니다.
`.bail on`은 스크립트에 오류가 생겼을 때 계속 진행하지 않도록 합니다. [SQLite CLI 공식 문서](https://sqlite.org/cli.html)

테이블 수와 데이터 수를 확인합니다. 이 명령은 점 명령이 아닌 SQL이므로 `;`로 끝냅니다.

```sql
SELECT 'customer' AS table_name, COUNT(*) AS row_count FROM customer
UNION ALL
SELECT 'menu', COUNT(*) FROM menu
UNION ALL
SELECT 'cafe_order', COUNT(*) FROM cafe_order
UNION ALL
SELECT 'order_item', COUNT(*) FROM order_item;

PRAGMA foreign_keys;
```

기본 샘플 기준 행 수는 차례로 **12, 10, 12, 24**, `foreign_keys`는 **1**입니다.

### 3-3. 쿼리 15개 실행하기

위에서 열어 둔 SQLite 내부에서 실행합니다.

```text
.read queries.sql
.quit
```

Q01~Q12는 결과 표를 출력합니다. Q13~Q14는 실제 수정·삭제 후 결과를 보여주고 되돌립니다.
Q15는 인덱스를 생성하고 실행 계획을 출력합니다. **인덱스는 유지되며 샘플 행은 원래 상태로 남습니다.**

다음에 다시 실행할 때는 **`schema.sql`과 `seed.sql`을 재실행하지 않고** 기존 DB에서 `queries.sql`만 실행합니다.

```bash
sqlite3 cafe.db
```

```text
.headers on
.mode column
.nullvalue NULL
.read queries.sql
.quit
```

`schema.sql`에는 기존 테이블을 삭제하는 명령이 없습니다. 기존 DB에 다시 실행하면 `table ... already exists` 오류가 납니다.
`seed.sql`을 다시 실행하면 중복 PK/UNIQUE 오류가 납니다. 이는 중복 초기화를 드러내기 위한 동작입니다.
처음부터 다시 시작할 때는 DB 연결을 닫고 기존 `cafe.db`를 백업한 뒤 다른 빈 DB 이름으로 실행합니다. 예: `sqlite3 cafe_new.db`.
GUI에서 실행 중 오류로 트랜잭션이 열린 채 남았다면 먼저 `ROLLBACK;`으로 해당 시도를 취소합니다.

### 3-4. CLI 실행 결과를 텍스트로 남기기

프로젝트 폴더에서 `sqlite3 cafe.db`로 접속한 뒤 입력합니다.

```text
.bail on
.headers on
.mode column
.nullvalue NULL
.echo on
.output results/my-queries.txt
.read queries.sql
.output stdout
.echo off
.quit
```

`my-queries.txt`에는 SQL 원문과 결과가 함께 기록됩니다. `.output stdout` 이후 출력은 다시 터미널로 돌아옵니다.
제출된 `results/queries.txt`는 아래 Python 검증으로 생성한 결과이며, CLI 출력과 **표 모양은 달라도 값은 비교할 수 있습니다**.
GUI 도구를 쓰는 경우에도 `schema.sql → seed.sql → queries.sql` 순서로 파일 전체를 실행합니다.
Q13~Q14는 한 문장만 골라 실행하지 말고 `BEGIN`부터 마지막 복원 확인 SELECT까지 함께 실행합니다.

### 3-5. 자동 재검증과 결과 재생성 — 선택

Python 3.9 이상을 대상으로 작성했으며, 실제 확인 버전은 3.13.5입니다.
`sqlite3` 모듈이 포함된 Python이면 `pip install` 없이 실행합니다. [Python sqlite3 문서](https://docs.python.org/3/library/sqlite3.html)

```bash
python3 verify.py
```

Windows에서 Python Launcher를 사용하면 다음과 같습니다.

```powershell
py verify.py
```

정상 실행 결과:

```text
결과: 58개 검사 통과. 실패 0개.
실행 결과: results/queries.txt
검증 근거: results/verification.txt
```

검증은 빈 메모리 DB를 만들고 SQL을 직접 실행합니다. 파일 저장·재접속은 별도의 임시 폴더에서 검사합니다.
사용자가 만든 `cafe.db`는 열거나 수정하지 않습니다. 성공하면 `results/`의 두 증거 파일을 갱신합니다.
실패하면 원인을 표준 오류로 출력하고 종료 코드 1을 반환하며, 기존 결과 파일은 갱신하지 않습니다.
**따라서 실패 후 남아 있는 결과 파일은 과거 성공 기록이며, 방금 실행이 성공했다는 뜻이 아닙니다.**

## 4. 테이블을 왜 이렇게 나눴는가

### 한 테이블의 한 행은 무엇을 뜻하는가

| 테이블 | 한 행의 의미 | 주요 컬럼 | 샘플 수 |
|---|---|---|---:|
| `customer` | 고객 한 명 | 고객 번호, 이름, 이메일, 가입일 | 12 |
| `menu` | 메뉴 한 종류 | 메뉴 번호, 이름, 분류, 현재 단가 | 10 |
| `cafe_order` | 고객이 한 번 한 주문 | 주문 번호, 고객 번호, 주문 시각 | 12 |
| `order_item` | 특정 주문에 들어간 메뉴 한 종류 | 상세 번호, 주문 번호, 메뉴 번호, 수량, 당시 단가 | 24 |

```text
customer (고객) 1 ───── N cafe_order (주문)
                              1
                              │
                              N
                         order_item (주문상세) N ───── 1 menu (메뉴)
```

**고객과 주문을 나눈 이유:** 김민수가 세 번 주문해도 이름과 이메일을 세 번 저장하지 않습니다.
고객 정보는 `customer`에 한 번 저장하고, 주문에는 `customer_id = 1`로 연결합니다.

**주문과 주문상세를 나눈 이유:** 한 주문에 아메리카노 2개와 크루아상 1개를 담을 수 있습니다.
메뉴가 늘어날 때마다 `메뉴1`, `메뉴2`, `메뉴3` 컬럼을 추가하는 대신 주문상세의 행을 추가합니다.
주문 1번은 주문 테이블에서는 1행, 상세 테이블에서는 2행입니다. **주문 건수와 상세 행 수는 다릅니다.**

**메뉴와 주문상세를 나눈 이유:** 메뉴의 기본 정보는 한 곳에 두고, 어느 주문에서 팔렸는지만 연결합니다.
단, `unit_price_won`은 이름과 달리 단순 중복이 아닙니다. **주문 당시 단가라는 별도의 사실**입니다.
현재 가격이 4,500원으로 바뀌어도 과거 4,000원에 주문한 기록은 그대로 남겨야 합니다.

**주문 총액 컬럼을 만들지 않은 이유:** 상세의 `수량 × 당시 단가`를 합하면 계산할 수 있습니다.
총액까지 별도로 저장하면 수량 수정 후 총액만 갱신하지 않는 불일치가 생길 수 있어 이 과제에서는 저장하지 않습니다.

**분류 테이블을 추가하지 않은 이유:** 분류는 이번 실습에서 이름 하나만 쓰므로 `menu.category`에 둡니다.
최소 4개 테이블 조건은 자연스러운 주문 구조만으로 충족합니다.

## 5. 이 프로젝트로 이해하는 핵심 개념

### 5-1. DB와 엑셀, 테이블·행·컬럼·스키마

테이블은 같은 종류의 데이터를 담는 표입니다. 행(row)은 고객 한 명 같은 개별 기록이고,
컬럼(column)은 이름·이메일 같은 항목입니다. 스키마(schema)는 **어떤 표와 항목, 연결 규칙을 둘지 정한 설계**입니다.

엑셀도 표를 나누고 조회·연결 작업을 할 수 있으므로 “엑셀은 관계를 전혀 표현할 수 없다”로 구분하면 부정확합니다.
이 과제에서 볼 차이는 **연결과 규칙을 DB가 강제한다는 점**입니다.
예를 들어 등록되지 않은 고객 번호로 주문을 넣거나, 주문이 남아 있는 고객을 삭제하려 하면 FK가 막습니다.
개발자가 조회할 때 주의하는 것뿐 아니라 **잘못 저장하려는 시점에 DB가 거부**하도록 만드는 것입니다.
구체적인 규칙은 [SQLite 제약조건](https://sqlite.org/lang_createtable.html)과 [FK 문서](https://sqlite.org/foreignkeys.html)를 기준으로 구현했습니다.

### 5-2. PK — 한 행을 구별하는 기본 키

`customer.customer_id`는 고객 한 명을 구별하는 번호입니다. 이것이 PK(Primary Key, 기본 키)입니다.
동명이인이 있어도 번호가 다르면 구분할 수 있습니다. 이 스키마에서는 같은 PK 번호를 두 행에 넣을 수 없습니다.

```text
customer_id | name
1           | 김민수
2           | 이서연
```

모든 테이블은 정수 PK를 가집니다. SQLite의 `INTEGER PRIMARY KEY`는 특별히 행 식별자와 연결되며,
INSERT에서 번호를 생략하거나 NULL로 전달하면 정수 번호를 배정합니다. 저장된 PK가 NULL인 행을 만든다는 뜻은 아닙니다.
샘플에서는 관계를 쉽게 추적하도록 번호를 직접 지정했습니다.
`AUTOINCREMENT`가 없어도 번호 배정은 가능하며, 번호를 절대 재사용하지 않는 추가 정책은 이 과제에 필요하지 않습니다. [공식 설명](https://sqlite.org/lang_createtable.html#rowid)

### 5-3. FK와 1:N — 다른 표의 한 행을 가리키기

FK(Foreign Key, 외래 키)는 다른 테이블의 키를 참조하는 컬럼입니다.
`cafe_order.customer_id`는 `customer.customer_id`를 참조합니다.

```text
customer                           cafe_order
customer_id | name                 order_id | customer_id
1           | 김민수               1        | 1
                                   3        | 1
                                   12       | 1
```

고객 1명이 주문 여러 건을 가질 수 있으므로 **고객 1 : 주문 N**입니다. N은 “여러 개가 가능하다”는 뜻입니다.
주문이 반드시 있어야 한다는 뜻은 아니므로 고객 10~12번처럼 0건도 가능합니다.
반대로 이 모델의 각 주문은 `NOT NULL` FK로 정확히 한 고객을 가리킵니다.
FK 컬럼에는 같은 번호가 반복될 수 있습니다. 여기에 UNIQUE까지 걸면 고객당 여러 주문을 허용하지 못합니다.

같은 방식으로 `cafe_order.order_id → order_item.order_id`, `menu.menu_id → order_item.menu_id`도 1:N입니다.
주문과 메뉴 사이의 여러 대 여러 연결은 주문상세가 중간에서 표현하지만, 직접 선언한 FK는 각각의 1:N 관계입니다.

**FK를 선언하는 것과 검사하는 것은 구분해야 합니다.** SQLite에서는 연결할 때마다 아래 설정을 명시합니다.
트랜잭션 안에서는 설정 변경이 적용되지 않으므로 `BEGIN` 전에 실행합니다. 세 SQL 파일 모두 첫 부분에 들어 있습니다. [공식 FK 활성화 규칙](https://sqlite.org/foreignkeys.html#fk_enable)

```sql
PRAGMA foreign_keys = ON;
PRAGMA foreign_keys;
```

두 번째 명령의 결과가 `1`이어야 합니다. 다만 이 값만 보고 끝내지 않고, `verify.py`는 잘못된 입력도 실제 시도합니다.

### 5-4. 제약조건과 자료형

제약조건(constraint)은 DB에 저장할 수 있는 값의 규칙입니다. [공식 문서](https://sqlite.org/lang_createtable.html)

| 규칙 | 이 프로젝트의 예 | 막는 상황 |
|---|---|---|
| PRIMARY KEY | `customer_id` | 같은 고객 번호의 중복 |
| NOT NULL | `customer.name` | 이름을 NULL로 저장 |
| UNIQUE | `customer.email` | 이미 쓰는 이메일을 다른 고객에게 재사용 |
| FOREIGN KEY | `cafe_order.customer_id` | 존재하지 않는 고객의 주문 |
| CHECK | 수량·가격의 자료형과 양수 조건 | 0개, 음수·소수·문자 수량/금액 |
| ON DELETE RESTRICT | 세 FK 모두 | 연결된 자식이 남아 있는 부모 삭제 |

`NOT NULL`은 빈 문자열 `''`까지 막지 않습니다. 이메일 UNIQUE도 이메일 주소 형식 검증을 뜻하지 않습니다.
`UNIQUE(order_id, menu_id)`는 **두 번호의 조합**을 중복 없이 저장한다는 뜻입니다.
같은 메뉴를 다른 주문에서 사는 것은 허용하고, 같은 주문에서는 수량을 늘립니다.

| 자료형 선택 | 사용 위치 | 선택 이유 |
|---|---|---|
| INTEGER | PK/FK, 수량, 원 단위 금액 | 번호와 개수, 소수 없는 원 단위를 표현 |
| TEXT | 이름, 이메일, 분류 | 글자로 된 정보 |
| TEXT 날짜 | `joined_on` | `YYYY-MM-DD`로 통일 |
| TEXT 일시 | `ordered_at` | `YYYY-MM-DD HH:MM:SS`로 통일, 모두 한국 현지 시각 |

SQLite에는 별도의 날짜 저장 자료형이 없어 이 프로젝트는 날짜를 TEXT로 저장합니다.
형식과 시간대를 동일하게 유지하면 문자열 정렬로도 날짜 순서를 비교할 수 있습니다.
`2026-9-1`처럼 자릿수가 다른 값이나 다른 시간대 문자열을 섞으면 이 전제가 깨집니다. [SQLite 자료형 문서](https://sqlite.org/datatype3.html)

SQLite의 일반 테이블은 `INTEGER` 선언만으로 모든 문자 입력을 거부하지 않습니다.
따라서 수량과 금액에는 `typeof(...) = 'integer'`와 `> 0`을 함께 검사했습니다.
예를 들어 수량 `1.5`나 `'많이'`는 막고, 저장 과정에서 정수로 변환 가능한 `'2'`는 정수 2로 저장될 수 있습니다.
날짜의 실제 달력 유효성, 이메일 형식, 분류 이름 목록 전체를 강제하는 기능까지 만들지는 않았습니다.

### 5-5. INSERT·SELECT·UPDATE·DELETE

| 명령 | 역할 | 이 프로젝트에서 보는 곳 |
|---|---|---|
| INSERT | 새로운 행 추가 | `seed.sql`의 고객·메뉴·주문·상세 입력 |
| SELECT | 조건에 맞는 행 조회 | Q01~Q12 |
| UPDATE | 이미 존재하는 행 수정 | Q13 아메리카노 현재 가격 변경 |
| DELETE | 조건에 맞는 행 삭제 | Q14 주문 없는 고객 삭제 |

UPDATE와 DELETE는 WHERE가 없으면 테이블의 모든 행을 대상으로 합니다.
Q13은 `WHERE menu_id = 1`, Q14는 `WHERE customer_id = 12`로 대상을 한정합니다.

Q13~Q14의 트랜잭션(transaction)은 여러 작업을 한 묶음으로 다루는 경계입니다.
`BEGIN`으로 시작하고, `COMMIT`이면 확정, `ROLLBACK`이면 그 묶음의 변경을 취소합니다.
이번에는 변경을 실제 수행하고 결과를 확인한 다음 ROLLBACK하여 반복 학습이 가능하게 했습니다. [SQLite 트랜잭션](https://sqlite.org/lang_transaction.html)

### 5-6. WHERE·ORDER BY·LIMIT

Q01은 “메뉴 중 4,500원 이하만 남기고, 가격이 낮은 순으로 정렬”합니다.
Q02의 `LIKE '%라테%'`는 이름 어디에든 '라테'가 있는 메뉴를 찾습니다.
Q03은 `시작 시각 이상 AND 종료 시각 미만`으로 기간을 표현합니다.
Q04는 내림차순으로 정렬한 뒤 `LIMIT 3`으로 3행만 남깁니다. [SELECT 문서](https://sqlite.org/lang_select.html)

SQL은 ORDER BY 없이 결과 순서를 보장하지 않습니다. 같은 가격·시각의 순서도 일정하게 하려고 PK를 보조 정렬 기준으로 넣었습니다.
단, Q15의 진단 명령 출력은 SQL 조회 정렬과 별개이며 DB 버전에 따라 표기가 달라질 수 있습니다.

### 5-7. INNER JOIN과 LEFT JOIN

JOIN은 관련된 테이블의 행을 연결해서 결과 표를 만드는 조회입니다. 테이블을 영구히 합치는 명령이 아닙니다.
FK가 저장 규칙을 맡는다면, JOIN의 `ON`은 **이번 조회에서 무엇을 기준으로 연결할지**를 지정합니다. [JOIN 공식 설명](https://sqlite.org/lang_select.html#determination_of_input_data_from_clause_processing)

Q05의 `ON c.customer_id = o.customer_id`는 주문의 고객 번호와 같은 고객 행을 찾습니다.
여기서 `c`, `o`는 테이블의 짧은 별명(alias)입니다.

**INNER JOIN:** 양쪽에 연결되는 행이 있는 결과만 남깁니다.
**LEFT JOIN:** 왼쪽 행은 연결 상대가 없어도 남기고, 오른쪽 컬럼을 NULL로 표시합니다.

Q08의 실제 결과 일부:

```text
customer_id | name   | order_id
1           | 김민수 | 1
1           | 김민수 | 3
1           | 김민수 | 12
...
10          | 임준서 | NULL
11          | 서예린 | NULL
12          | 장우진 | NULL
```

같은 Q08에서 LEFT JOIN만 INNER JOIN으로 바꾸면 마지막 세 고객이 사라집니다.
원본 Q08은 **15행**, INNER JOIN으로 바꾼 비교 쿼리는 **12행**입니다. 고객 1명이 여러 주문에 연결되므로 고객 수 12명과 결과 행 수도 다릅니다.
NULL은 0이 아니라 연결되는 값이 없는 상태입니다. 검사할 때는 `= NULL` 대신 `IS NULL`을 씁니다.

### 5-8. GROUP BY·COUNT·SUM·AVG

GROUP BY는 “어떤 값이 같은 행끼리 한 묶음으로 볼 것인가”를 정합니다.
집계 함수는 그 묶음에서 개수·합계·평균을 계산합니다. [집계 함수 공식 문서](https://sqlite.org/lang_aggfunc.html)

Q09에서 김민수의 주문 번호 `1, 3, 12`를 고객 1번 묶음으로 모으면 `COUNT(o.order_id) = 3`입니다.
임준서는 연결 결과에 행 하나가 남지만 주문 번호가 NULL이므로 `COUNT(o.order_id) = 0`입니다.
여기서 COUNT(*)를 사용하면 NULL 주문이 붙은 행도 세어 1건으로 잘못 해석할 수 있습니다.

Q10에서 아메리카노의 판매 수량은 `2 + 1 + 1 + 1 = 5`, 판매금액은 `8,000 + 4,000 + 4,000 + 4,000 = 20,000원`입니다.
GROUP BY가 메뉴별로 묶고 SUM이 각 묶음을 합산합니다.
Q11의 coffee는 현재 메뉴 가격 `4,000, 4,500, 5,000, 4,500, 5,000`의 평균이므로 `4,600원`입니다.
이는 주문 평균 금액이 아니라 **메뉴 종류별 가격의 평균**입니다.

고객 이름이 같더라도 합쳐지지 않도록 Q09는 `customer_id, name`으로 그룹화합니다.
또한 주문상세까지 연결하면 주문 한 건이 여러 행으로 늘 수 있으므로, 주문 횟수를 셀 때 상세를 불필요하게 JOIN하지 않았습니다.

### 5-9. 서브쿼리와 NOT EXISTS

서브쿼리(subquery)는 다른 SQL 안에 들어 있는 조회입니다.
Q12는 각 고객에 대해 “이 고객 번호를 참조하는 주문이 존재하는가?”를 조건으로 표현합니다.
NOT EXISTS는 그런 주문이 **하나도 없을 때** 참이 됩니다. 결과는 고객 10, 11, 12번입니다. [EXISTS 공식 설명](https://sqlite.org/lang_expr.html#the_exists_operator)

안쪽의 `SELECT 1`은 주문 번호 1을 찾으라는 뜻이 아닙니다. 반환할 값보다 행의 존재 여부가 중요하다는 표현입니다.
이 설명은 조건을 이해하기 위한 논리적 흐름이며, DB가 반드시 고객마다 그대로 반복 실행한다는 물리 실행 보장은 아닙니다.

### 5-10. 인덱스 — 찾는 경로를 추가하기

책의 찾아보기처럼, 인덱스(index)는 특정 값으로 행을 찾아가는 별도 구조입니다.
Q03처럼 기간 검색에 쓰는 `cafe_order.ordered_at`에 명시적 인덱스 하나를 추가했습니다.
Q15의 `CREATE INDEX`는 조회 결과를 바꾸는 것이 아니라 가능한 검색 경로를 추가합니다. [SQLite 쿼리 계획](https://sqlite.org/queryplanner.html)

```sql
CREATE INDEX IF NOT EXISTS idx_cafe_order_ordered_at
ON cafe_order(ordered_at);
```

`PRAGMA index_info`로 `ordered_at`을 확인하고, `EXPLAIN QUERY PLAN`으로 실제 선택된 계획을 봅니다.
이번 실행 기록에는 `SEARCH cafe_order USING INDEX idx_cafe_order_ordered_at`이 나왔습니다.
이는 해당 환경에서 인덱스를 선택했다는 뜻이지, 12행 샘플에서 속도가 몇 배 빨라졌다는 측정은 아닙니다.
DB 버전·통계·데이터 규모에 따라 다른 계획이 나올 수 있습니다. [EXPLAIN QUERY PLAN 공식 주의사항](https://sqlite.org/eqp.html)

인덱스는 저장 공간과 입력·수정 시 관리 비용도 필요합니다. 모든 컬럼에 무조건 만들지 않습니다.
UNIQUE 때문에 SQLite가 자동으로 만든 인덱스와, Q15에서 명시적으로 만든 학습용 인덱스는 구분합니다.

## 6. 쿼리 15개를 읽는 순서

전체 SQL은 [queries.sql](queries.sql), 결과는 [results/queries.txt](results/queries.txt)에 있습니다.
결과 파일에서 `=== Q07`처럼 번호를 검색하면 SQL과 표를 함께 볼 수 있습니다.

| 번호 | 읽을 순서와 주요 구문 | 기본 샘플에서 확인할 결과 |
|---|---|---|
| Q01 | menu → WHERE 가격 → ORDER BY | 3,500원 크루아상부터 4,500원 메뉴까지 5개 |
| Q02 | menu → LIKE 이름 검색 | 카페라테·바닐라라테·초콜릿라테 3개 |
| Q03 | cafe_order → 시작 포함/끝 제외 → 시각 정렬 | 주문 5·6·7·8번 |
| Q04 | 주문을 최신순 정렬 → LIMIT 3 | 주문 12·11·10번 |
| Q05 | 주문 → 고객 번호로 INNER JOIN | 주문 1~4번에 고객 이름 표시 |
| Q06 | 주문상세 → 메뉴 INNER JOIN → 1번 주문 | 아메리카노 8,000원 + 크루아상 3,500원 |
| Q07 | 고객 → 주문 → 상세 → 메뉴 | 김민수의 주문 3건에 속한 상세 6행 |
| Q08 | 고객을 왼쪽에 두고 LEFT JOIN | 주문 없는 고객까지 총 15행 |
| Q09 | 고객-주문 연결 → 고객별 묶기 → COUNT | 김민수 3건, 이서연 2건, 미주문 고객 0건 |
| Q10 | 메뉴-상세 연결 → 메뉴별 묶기 → SUM | 치즈케이크 26,000원으로 1위, 전체 합계 145,000원 |
| Q11 | 메뉴를 category별로 묶기 → COUNT·AVG | coffee 5개, 평균 4,600원 |
| Q12 | 고객 → 해당 고객 주문의 NOT EXISTS | 고객 10·11·12번 |
| Q13 | BEGIN → 변경 전 → UPDATE → 변경 후 → ROLLBACK | 현재 가격 4,000→4,500→4,000원, 당시 단가 유지 |
| Q14 | BEGIN → 존재 확인 → DELETE → 부재 확인 → ROLLBACK | 고객 12번의 개수 1→0→1 |
| Q15 | CREATE INDEX → 컬럼 확인 → 실행 계획 | 주문 시각 인덱스 1개 생성 |

### 가장 복잡한 쿼리 Q07을 작은 데이터로 추적하기

Q07은 4개 테이블을 연결합니다. 읽을 때는 SELECT의 긴 목록보다 FROM과 JOIN의 연결 관계부터 봅니다.

```text
customer에서 customer_id = 1인 고객: 김민수
    ↓ cafe_order.customer_id = 1
주문 번호: 1, 3, 12
    ↓ order_item.order_id가 해당 주문 번호와 일치
주문상세: 1번 주문 2행 + 3번 주문 2행 + 12번 주문 2행
    ↓ menu.menu_id = order_item.menu_id
메뉴 번호에 아메리카노·크루아상 등의 이름을 연결
    ↓ SELECT와 곱셈, ORDER BY
고객 이름 / 주문 번호 / 메뉴 이름 / 수량 / 줄별 금액의 6행
```

첫 행은 `김민수 → 주문 1 → 상세 1 → 메뉴 1 아메리카노`입니다.
수량 2에 당시 단가 4,000을 곱해 `line_total_won = 8,000`을 얻습니다.
JOIN을 “표 전체를 합친다”가 아니라 **번호가 맞는 행을 연결해 필요한 항목을 가져온다**로 설명할 수 있어야 합니다.
이 흐름은 논리적 설명이며 DB 내부의 실제 조인 실행 순서는 옵티마이저가 선택할 수 있습니다.

## 7. 보너스와 구현에서 주의한 문제

### 7-1. 같은 요구를 JOIN과 서브쿼리로 풀기

Q12와 같은 “주문 없는 고객”을 LEFT JOIN으로 표현한 **학습용 비교 SQL**입니다. 필수 15개에 추가 계산하지 않습니다.

```sql
SELECT c.customer_id, c.name
FROM customer AS c
LEFT JOIN cafe_order AS o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;
```

LEFT JOIN 방식은 “연결하고, 연결되지 않은 행만 남긴다”입니다.
Q12의 NOT EXISTS 방식은 “관련 주문이 존재하지 않는 고객만 남긴다”입니다.
둘 다 기본 샘플에서 `(10, 임준서), (11, 서예린), (12, 장우진)`입니다. 읽기 쉬운 방식이 다를 뿐 어느 쪽이 항상 빠르다고 단정하지 않습니다.

### 7-2. FK 오류를 일부러 내고 올바르게 해결하기

학습용 실패 입력이며 `seed.sql`에 포함하지 않았습니다. FK를 켠 상태에서 별도로 실행하면 오류가 나야 합니다.

```sql
PRAGMA foreign_keys = ON;
INSERT INTO cafe_order (order_id, customer_id, ordered_at)
VALUES (90, 999, '2026-10-01 10:00:00');
```

실제 검증에서 `FOREIGN KEY constraint failed`가 발생했습니다.
원인은 `customer_id = 999`인 부모 고객이 없기 때문입니다.
고객이 1번이라면 1번을 참조해야 하고, 새 고객의 주문이라면 **그 고객을 먼저 INSERT한 뒤 반환·지정된 번호를 참조**해야 합니다.
FK 검사를 꺼서 넣는 것은 연결이 깨진 데이터를 허용하는 것이므로 올바른 해결이 아닙니다.
검증 스크립트는 부모 고객 90번 → 주문 90번 → 상세 90번의 정상 입력도 수행해 확인한 뒤 되돌립니다.

### 7-3. 기존 쿼리로 보는 미니 리포트

| 지표와 정의 | 최종 SQL | 해석 |
|---|---|---|
| 고객별 주문 건수 | Q09 | 고객의 반복 주문을 파악. 주문상세 수와 구분 |
| 메뉴별 판매금액 | Q10 | 수량 × 주문 당시 단가의 합. 판매된 메뉴만 표시 |
| 분류별 현재 메뉴 평균 단가 | Q11 | 판매량 가중치 없는 메뉴 가격 평균 |

표본은 학습용 가상 주문입니다. 환불·할인·세금·취소를 모델링하지 않았으므로 Q10은 상세 금액 합계이며 실제 회계 매출로 확대 해석하지 않습니다.

### 7-4. 설계에서 주의한 점과 해결 근거

주문과 주문상세를 혼동하면 건수가 두 배로 부풀 수 있습니다. **행이 뜻하는 단위**를 먼저 정하고 Q09에서는 주문 테이블까지만 연결했습니다.
LEFT JOIN 뒤 COUNT(*)를 쓰면 주문 없는 고객도 1건처럼 보일 수 있어 **NULL이 아닌 주문 번호를 세도록** 했습니다.
현재 메뉴 단가로 과거 금액을 계산하면 가격 변경이 과거 주문까지 바꾸므로 **주문 당시 단가를 따로 저장**했습니다.

위 내용은 코드의 설계 근거입니다. 피어 평가에서 요구하는 “본인이 가장 어려웠던 부분”은 실제로 이해가 막혔던 지점과 확인 과정을 자신의 경험으로 설명해야 합니다.
발생하지 않은 오류나 직접 하지 않은 작업을 경험담처럼 작성하지 않습니다.

## 8. 검증 범위, 한계, 평가 준비

### 실제 확인한 상태

기록된 환경은 **Linux / Python 3.13.5 / Python 내장 SQLite 3.46.1**입니다.
[verification.txt](results/verification.txt)에 **58개 검사 통과**와 실제 오류 메시지, 사용한 실패 SQL이 있습니다.
이는 검증 스크립트의 성공 검사 개수이며, 별도 테스트 프레임워크의 테스트 함수 58개라는 뜻은 아닙니다.

검사는 테이블·PK/FK·행 수, 21가지 잘못된 입력의 차단, 정상 부모→자식 입력, Q01~Q12 전체 기대값과 정렬,
UPDATE/DELETE와 원복, 인덱스 컬럼, 두 번의 전체 실행, 날짜 경계, DB 파일 저장 후 재접속을 포함합니다.
추가 수동 점검에서는 SQL 파일별로 연결을 새로 열어 순차 실행하고, JOIN 비교·보너스 결과 및 잘못된 SQL의 종료 코드와 결과 파일 보존도 확인했습니다.
통과한 검사를 “기능별 SQL 검사”와 “초기화부터 조회·수정·재실행까지의 통합 검사”로 구분해 설명할 수 있습니다.

**별도 미검증:** 사용자 macOS/Windows에서의 실제 실행, sqlite3 전용 CLI 및 GUI 조작, 대규모 성능 측정, GitHub Actions CI.
현재 증거는 Python sqlite3를 통해 실제 SQLite 엔진에서 SQL을 실행한 결과입니다. CLI 설치·실행 안내는 공식 문서를 기준으로 작성했습니다.
CI 설정이나 프레임워크는 단순한 SQL 과제 범위를 유지하기 위해 추가하지 않았습니다.

### verify.py를 읽어야 하는 경우

SQL 학습에는 필수 파일이 아니지만, 검증의 근거를 볼 때는 다음 순서로 읽습니다.

| 함수 | 맡은 일 |
|---|---|
| `main()` | 빈 DB 구성, 제약조건 검사, 기대값 비교, 반복·재접속 검사, 증거 저장 |
| `statements()` | SQL을 줄 단위로 누적하고 완성된 문장을 실행 단위로 전달 |
| `run_queries()` | Q번호 순서대로 SQL을 실행하고 결과값과 결과 텍스트를 수집 |
| `check()` | 기대 조건이 맞으면 PASS 기록, 틀리면 실패 처리 |
| `snapshot()` | 4개 테이블의 모든 행을 읽어 원본 보존 여부 비교 |
| `expect_error()` | 실패해야 할 입력이 올바른 제약조건 때문에 차단되는지 확인 후 원복 |

검증용 SAVEPOINT는 임시 변경을 되돌릴 지점을 정하는 장치입니다. 제출 SQL의 서비스 기능이 아닙니다.
검증기는 범용 SQL 파서를 새로 만들지 않고 SQLite의 `complete_statement()`를 사용합니다.
이 프로젝트처럼 **SQL 한 문장이 끝나는 줄을 다른 문장과 분리하는 형식**을 전제로 합니다.

### 남겨 둔 범위와 한계

고객 이메일 하나당 계정 하나, 한 주문의 같은 메뉴는 한 줄, 금액·수량은 양의 정수라는 **실습 모델의 규칙**을 사용합니다.
실제 카페의 모든 운영 규칙을 구현했다는 뜻은 아닙니다.
주문이 반드시 상세 1행 이상을 가져야 한다는 교차 테이블 규칙, 날짜의 달력 유효성, 이름의 공백만 입력,
이메일 형식, 옵션·할인·환불·결제·재고·시간대 변환은 구현하지 않았습니다.
뷰·트리거·프로시저 없이 과제의 관계와 SQL 조회에 집중한 범위입니다.

### 제공된 평가표와 연결할 설명

| 평가 항목 | 이 저장소에서 설명할 근거 |
|---|---|
| 항목 1: 구현과 증거 | SQL 3개, 4개 테이블의 행 수, FK 실패 기록, Q01~Q15 결과 |
| 항목 2: 설계 이유 | 4절 테이블 분리, 5-3 관계, 5-4 자료형, 5-10 인덱스 |
| 항목 3: 개념 이해 | 엑셀 비교, PK/FK 구분, Q08 JOIN 차이, Q09~Q11 묶음과 집계 |
| 항목 4: 복잡한 쿼리와 어려움 | Q07의 4단계 연결을 실제 행으로 설명, 본인의 실제 학습 경험 정리 |

**구현·검증 자료가 준비된 것과 학습자가 설명할 수 있는 것은 별개입니다.**
코드와 결과를 직접 연결해 설명하는 준비가 남아 있으며, 이 저장소만으로 평가 통과를 보장하지 않습니다.
