"""SQL 제출물을 실제 SQLite로 검증하고 결과 텍스트를 다시 만듭니다.

선택 실행: python3 verify.py (Windows: py verify.py)
Python 표준 라이브러리만 사용합니다. 서비스/API가 아니며 cafe.db를 건드리지 않습니다.
"""

import platform
import re
import sqlite3
import sys
import tempfile
from contextlib import closing
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TABLES = ("customer", "menu", "cafe_order", "order_item")


def statements(sql: str):
    """한 줄씩 누적하다 SQLite가 완성된 문장으로 판단하면 실행 단위로 내보냅니다."""
    pending = ""
    for line in sql.splitlines(keepends=True):
        pending += line
        if sqlite3.complete_statement(pending):
            yield pending.strip()
            pending = ""
    # 이 프로젝트는 한 줄에 여러 SQL 문장을 쓰지 않고, 마지막 문장은 ;로 끝냅니다.
    if pending.strip():
        raise ValueError("SQL 문장이 끝나지 않았습니다. 마지막 세미콜론을 확인하세요.")


def check(condition: bool, description: str, report: list[str]) -> None:
    """조건이 틀리면 즉시 실패시키고, 맞으면 검증 근거를 한 줄 기록합니다."""
    if not condition:
        raise AssertionError(description)
    report.append(f"PASS | {description}")


def snapshot(db: sqlite3.Connection) -> dict:
    """4개 테이블의 모든 행을 PK 순서로 읽어 수정·삭제 전후를 비교합니다."""
    # 테이블 이름은 사용자 입력이 아니라 위 TABLES에 고정된 이름만 사용합니다.
    return {table: db.execute(f"SELECT * FROM {table} ORDER BY 1").fetchall()
            for table in TABLES}


def expect_error(db: sqlite3.Connection, sql: str, error_text: str,
                 description: str, report: list[str]) -> None:
    """잘못된 SQL이 지정한 제약조건 때문에 차단되는지 검사하고 시도한 변경을 되돌립니다."""
    db.execute("SAVEPOINT invalid_input")
    try:
        try:
            db.execute(sql)
        except sqlite3.IntegrityError as error:
            check(error_text in str(error), f"{description}: {error}", report)
            report.append(f"  SQL: {sql}")
        else:
            raise AssertionError(f"차단되어야 하는 입력이 허용됨: {description}")
    finally:
        db.execute("ROLLBACK TO invalid_input")
        db.execute("RELEASE invalid_input")


def run_queries(db: sqlite3.Connection, sections: list) -> tuple[dict, str]:
    """Q01~Q15의 실제 SQL을 실행하며 SQL 원문·컬럼명·결과 행을 함께 기록합니다."""
    results = {}
    log = [f"SQLite {sqlite3.sqlite_version} | 실제 실행 결과", "NULL은 연결되는 값이 없음을 나타냅니다.", ""]
    for query_id, title, sql in sections:
        log.extend([f"=== {query_id} | {title} ===", ""])
        result_sets = []
        for statement in statements(sql):
            log.append(statement)
            cursor = db.execute(statement)
            if cursor.description is None:
                log.append("OK (결과 표가 없는 SQL 문장)")
            else:
                rows = cursor.fetchall()
                result_sets.append(rows)
                log.append(" | ".join(column[0] for column in cursor.description))
                for row in rows:
                    log.append(" | ".join("NULL" if value is None else str(value) for value in row))
                log.append(f"({len(rows)} rows)")
            log.append("")
        results[query_id] = result_sets
    return results, "\n".join(log).rstrip() + "\n"


def main() -> None:
    """빈 DB 구성 → 제약조건 → 쿼리 기대값 → 재실행·파일 보존을 검사한 뒤 증거를 저장합니다."""
    report = [f"Python {platform.python_version()} | SQLite {sqlite3.sqlite_version} | {platform.system()}",
              "검증 대상: schema.sql, seed.sql, queries.sql", ""]
    source = (ROOT / "queries.sql").read_text(encoding="utf-8")
    # -- Q번호 | 설명 형식을 읽습니다. SQL 실행 순서와 결과 파일의 순서를 일치시킵니다.
    parts = re.split(r"(?m)^-- (Q[0-9]{2}) \| (.+)\n", source)
    sections = [tuple(parts[index:index + 3]) for index in range(1, len(parts), 3)]
    check([item[0] for item in sections] == [f"Q{i:02d}" for i in range(1, 16)],
          "Q01~Q15가 중복 없이 순서대로 존재", report)
    categories = [title.split(" | ")[0] for _, title, _ in sections]
    check(categories == ["기본 조회"] * 4 + ["조인"] * 4 + ["집계"] * 3
          + ["서브쿼리", "수정", "삭제", "인덱스"], "평가표의 7개 범주 및 개수 일치", report)

    # isolation_level=None: 자동으로 시작되는 트랜잭션 없이 SQL 파일의 BEGIN/ROLLBACK을 따릅니다.
    with closing(sqlite3.connect(":memory:", isolation_level=None)) as db:
        for filename in ("schema.sql", "seed.sql"):
            db.executescript((ROOT / filename).read_text(encoding="utf-8"))
        db.executescript(parts[0])  # queries.sql의 연결 설정(PRAGMA)을 그대로 실행합니다.
        original = snapshot(db)
        check({key: len(rows) for key, rows in original.items()} ==
              {"customer": 12, "menu": 10, "cafe_order": 12, "order_item": 24},
              "샘플 행 수: 고객 12 / 메뉴 10 / 주문 12 / 주문상세 24", report)
        actual_tables = {row[0] for row in db.execute(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'")}
        check(actual_tables == set(TABLES), "도메인 테이블 정확히 4개", report)
        for table in TABLES:
            columns = db.execute(f"PRAGMA table_info({table})").fetchall()
            check(sum(column[5] > 0 for column in columns) == 1, f"{table}: PK 1개", report)
        fk_count = sum(len(db.execute(f"PRAGMA foreign_key_list({table})").fetchall()) for table in TABLES)
        check(fk_count == 3, "FK 3개로 고객-주문 / 주문-상세 / 메뉴-상세 연결", report)
        check(db.execute("PRAGMA foreign_keys").fetchone() == (1,), "현재 연결 FK 검사 활성화", report)
        check(db.execute("PRAGMA foreign_key_check").fetchall() == [], "샘플에 FK 위반 없음", report)
        check(db.execute("PRAGMA integrity_check").fetchone() == ("ok",), "DB 구조 무결성 검사 ok", report)
        check(db.execute("SELECT name FROM sqlite_master WHERE type IN ('view', 'trigger')").fetchall() == [],
              "뷰·트리거 없음", report)

        # 잘못된 입력이 실제 차단되는지 확인합니다. 문자열 검사는 오류의 종류도 확인합니다.
        invalid_cases = [
            ("없는 고객 참조", "INSERT INTO cafe_order VALUES (90, 999, '2026-10-01 10:00:00')", "FOREIGN KEY"),
            ("없는 주문 참조", "INSERT INTO order_item VALUES (90, 999, 1, 1, 4000)", "FOREIGN KEY"),
            ("없는 메뉴 참조", "INSERT INTO order_item VALUES (90, 1, 999, 1, 4000)", "FOREIGN KEY"),
            ("UPDATE로 FK 훼손 차단", "UPDATE cafe_order SET customer_id = 999 WHERE order_id = 1", "FOREIGN KEY"),
            ("주문 있는 고객 삭제 차단", "DELETE FROM customer WHERE customer_id = 1", "FOREIGN KEY"),
            ("상세 있는 주문 삭제 차단", "DELETE FROM cafe_order WHERE order_id = 1", "FOREIGN KEY"),
            ("판매된 메뉴 삭제 차단", "DELETE FROM menu WHERE menu_id = 1", "FOREIGN KEY"),
            ("중복 PK 차단", "INSERT INTO customer VALUES (1, '테스트', 'test@example.com', '2026-10-01')", "UNIQUE"),
            ("중복 이메일 차단", "UPDATE customer SET email = 'customer01@example.com' WHERE customer_id = 2", "UNIQUE"),
            ("중복 메뉴명 차단", "UPDATE menu SET name = '아메리카노' WHERE menu_id = 2", "UNIQUE"),
            ("같은 주문의 같은 메뉴 중복 차단", "INSERT INTO order_item VALUES (90, 1, 1, 1, 4000)", "UNIQUE"),
            ("NULL 이름 차단", "UPDATE customer SET name = NULL WHERE customer_id = 1", "NOT NULL"),
            ("NULL 고객 FK 차단", "UPDATE cafe_order SET customer_id = NULL WHERE order_id = 1", "NOT NULL"),
            ("0개 수량 차단", "UPDATE order_item SET quantity = 0 WHERE order_item_id = 1", "CHECK"),
            ("음수 수량 차단", "UPDATE order_item SET quantity = -1 WHERE order_item_id = 1", "CHECK"),
            ("소수 수량 차단", "UPDATE order_item SET quantity = 1.5 WHERE order_item_id = 1", "CHECK"),
            ("문자 수량 차단", "UPDATE order_item SET quantity = '많이' WHERE order_item_id = 1", "CHECK"),
            ("0원 메뉴 차단", "UPDATE menu SET price_won = 0 WHERE menu_id = 1", "CHECK"),
            ("소수 메뉴 가격 차단", "UPDATE menu SET price_won = 4000.5 WHERE menu_id = 1", "CHECK"),
            ("문자 메뉴 가격 차단", "UPDATE menu SET price_won = '무료' WHERE menu_id = 1", "CHECK"),
            ("음수 주문 단가 차단", "UPDATE order_item SET unit_price_won = -1 WHERE order_item_id = 1", "CHECK"),
        ]
        for description, sql, error_text in invalid_cases:
            expect_error(db, sql, error_text, description, report)
        check(snapshot(db) == original, "오류 입력 검사 후 모든 원본 행 보존", report)

        # 오류의 올바른 해결: 검사를 끄는 대신 참조할 부모를 먼저 만든 뒤 자식을 넣습니다.
        db.execute("SAVEPOINT valid_input")
        db.execute("INSERT INTO customer VALUES (90, '테스트', 'test@example.com', '2026-10-01')")
        db.execute("INSERT INTO cafe_order VALUES (90, 90, '2026-10-01 10:00:00')")
        db.execute("INSERT INTO order_item VALUES (90, 90, 1, 1, 4000)")
        check(db.execute("SELECT customer_id FROM cafe_order WHERE order_id = 90").fetchone() == (90,),
              "부모 고객 → 주문 → 주문상세 순서의 정상 입력 성공", report)
        db.execute("ROLLBACK TO valid_input")
        db.execute("RELEASE valid_input")

        results, query_log = run_queries(db, sections)
        expected = {
            "Q01": [(10, '크루아상', 3500), (1, '아메리카노', 4000), (2, '카페라테', 4500),
                    (4, '카푸치노', 4500), (8, '얼그레이티', 4500)],
            "Q02": [(2, '카페라테', 4500), (3, '바닐라라테', 5000), (6, '초콜릿라테', 5500)],
            "Q03": [(5, 4, '2026-10-01 09:00:00'), (6, 5, '2026-10-01 12:00:00'),
                    (7, 2, '2026-10-02 10:00:00'), (8, 6, '2026-10-02 15:00:00')],
            "Q04": [(12, 1, '2026-10-04 12:00:00'), (11, 9, '2026-10-04 11:00:00'),
                    (10, 8, '2026-10-03 16:00:00')],
            "Q05": [(1, 1, '김민수', '2026-09-29 10:00:00'), (2, 2, '이서연', '2026-09-29 13:00:00'),
                    (3, 1, '김민수', '2026-09-30 09:00:00'), (4, 3, '박지훈', '2026-09-30 16:00:00')],
            "Q06": [(1, '아메리카노', 2, 4000, 8000), (1, '크루아상', 1, 3500, 3500)],
            "Q07": [('김민수', 1, '아메리카노', 2, 8000), ('김민수', 1, '크루아상', 1, 3500),
                    ('김민수', 3, '바닐라라테', 1, 5000), ('김민수', 3, '크루아상', 2, 7000),
                    ('김민수', 12, '아메리카노', 1, 4000), ('김민수', 12, '카페라테', 1, 4500)],
            "Q08": [(1, '김민수', 1), (1, '김민수', 3), (1, '김민수', 12), (2, '이서연', 2),
                    (2, '이서연', 7), (3, '박지훈', 4), (4, '최유진', 5), (5, '정현우', 6),
                    (6, '한지민', 8), (7, '오수빈', 9), (8, '강도윤', 10), (9, '윤하린', 11),
                    (10, '임준서', None), (11, '서예린', None), (12, '장우진', None)],
            "Q09": [(1, '김민수', 3), (2, '이서연', 2), (3, '박지훈', 1), (4, '최유진', 1),
                    (5, '정현우', 1), (6, '한지민', 1), (7, '오수빈', 1), (8, '강도윤', 1),
                    (9, '윤하린', 1), (10, '임준서', 0), (11, '서예린', 0), (12, '장우진', 0)],
            "Q10": [(9, '치즈케이크', 4, 26000), (1, '아메리카노', 5, 20000), (2, '카페라테', 4, 18000),
                    (7, '레몬에이드', 3, 18000), (10, '크루아상', 5, 17500), (3, '바닐라라테', 3, 15000),
                    (5, '콜드브루', 3, 15000), (6, '초콜릿라테', 2, 11000), (4, '카푸치노', 1, 4500)],
            "Q11": [('ade', 1, 6000.0), ('coffee', 5, 4600.0), ('dessert', 2, 5000.0),
                    ('non_coffee', 1, 5500.0), ('tea', 1, 4500.0)],
            "Q12": [(10, '임준서'), (11, '서예린'), (12, '장우진')],
        }
        for query_id, rows in expected.items():
            check(results[query_id] == [rows], f"{query_id}: 전체 결과값 및 정렬 순서 일치", report)
        check(results["Q13"] == [[('before', 1, 4000)], [(1,)], [('after', 4500, 4000)], [('restored', 1, 4000)]],
              "Q13: 1행 수정 / 과거 단가 유지 / ROLLBACK 복원", report)
        check(results["Q14"] == [[('before', 1)], [(1,)], [('after', 0)], [('restored', 1)]],
              "Q14: 1행 삭제 / 사라짐 확인 / ROLLBACK 복원", report)
        check(results["Q15"][0] == [(0, 2, 'ordered_at')], "Q15: ordered_at 인덱스 생성 및 컬럼 확인", report)
        report.append(f"INFO | Q15 실행 계획: {results['Q15'][1]}")
        check(snapshot(db) == original, "15개 쿼리 실행 후 원본 데이터 전체 일치", report)
        again, _ = run_queries(db, sections)
        # 실행 계획 텍스트는 SQLite 버전별로 달라질 수 있어 기능 결과와 분리합니다.
        check(all(again[key] == results[key] for key in expected) and again['Q13'] == results['Q13']
              and again['Q14'] == results['Q14'], "전체 쿼리 2회 실행 시 동일한 조회·수정·삭제 결과", report)
        check(snapshot(db) == original, "2회 실행 후에도 원본 데이터 전체 일치", report)
        check(db.execute("SELECT COUNT(*) FROM sqlite_master WHERE name = 'idx_cafe_order_ordered_at'").fetchone() == (1,),
              "인덱스 재실행 시 중복 생성 없음", report)

        # Q03 원문으로 경계 시각을 검사합니다. 검사 뒤에는 추가 주문을 모두 되돌립니다.
        db.execute("SAVEPOINT date_boundary")
        db.execute("INSERT INTO cafe_order VALUES (100, 1, '2026-10-01 00:00:00'),"
                   "(101, 1, '2026-10-02 23:59:59'), (102, 1, '2026-10-03 00:00:00')")
        q03 = next(sql for query_id, _, sql in sections if query_id == 'Q03')
        check([row[0] for row in db.execute(q03)] == [100, 5, 6, 7, 8, 101],
              "Q03: 시작 0시 포함 / 마지막 날 23:59:59 포함 / 다음 날 0시 제외", report)
        db.execute("ROLLBACK TO date_boundary")
        db.execute("RELEASE date_boundary")

        # 메모리뿐 아니라 임시 DB 파일에 저장하고 다시 연결해 데이터 보존도 확인합니다.
        with tempfile.TemporaryDirectory() as folder:
            path = str(Path(folder) / 'cafe.db')
            with closing(sqlite3.connect(path)) as saved:
                db.backup(saved)
            with closing(sqlite3.connect(path, isolation_level=None)) as reopened:
                reopened.execute("PRAGMA foreign_keys = ON")
                check(snapshot(reopened) == original, "DB 파일 저장 → 연결 종료 → 재접속 후 데이터 전체 일치", report)
                expect_error(reopened, "INSERT INTO cafe_order VALUES (90, 999, '2026-10-01 10:00:00')",
                             "FOREIGN KEY", "재접속 후에도 명시적으로 켠 FK가 실제 차단", report)

    count = sum(line.startswith('PASS |') for line in report)
    report.append(f"\n결과: {count}개 검사 통과. 실패 0개.")
    results_dir = ROOT / 'results'
    results_dir.mkdir(exist_ok=True)
    # 검증이 모두 성공한 뒤에만 결과 파일을 갱신합니다. 실패하면 이전 증거를 덮어쓰지 않습니다.
    (results_dir / 'queries.txt').write_text(query_log, encoding='utf-8')
    (results_dir / 'verification.txt').write_text('\n'.join(report) + '\n', encoding='utf-8')
    print(report[-1].strip())
    print('실행 결과: results/queries.txt')
    print('검증 근거: results/verification.txt')


if __name__ == '__main__':
    try:
        main()
    except (sqlite3.Error, OSError, ValueError, AssertionError) as error:
        print(f'검증 실패: {error}', file=sys.stderr)
        sys.exit(1)
