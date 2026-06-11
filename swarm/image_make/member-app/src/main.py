from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import psycopg2
from psycopg2.extras import RealDictCursor
import os

app = FastAPI()

# 환경변수 매핑 (프록시 쓰기: 5432, 읽기: 5433)
WRITABLE_URL = os.getenv("WRITABLE_URL", "postgresql://scott:tiger@localhost:5432/scott_db")
READONLY_URL = os.getenv("READONLY_URL", "postgresql://scott:tiger@localhost:5433/scott_db")

# POST 요청으로 들어올 JSON 데이터 규격 정의
class MemberCreate(BaseModel):
    name: str
    addr: str

@app.get("/")
def read_root():
    return {"message": "hello, fastapi!"}

@app.get("/members")
def read_members():
    conn = psycopg2.connect(READONLY_URL)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    # member 레코드 긁어오기 (읽기 전용 프록시 5433 포트 사용)
    cursor.execute("SELECT * FROM member;")
    rows = cursor.fetchall()
    
    cursor.close()
    conn.close()
    return {"status": "success", "data": rows}

# post 방식으로 json 문자열 보내서 회원정보가 추가 되는지 확인하기 
# curl -X POST http://172.16.8.200:8080/members \
#      -H "Content-Type: application/json" \
#      -d '{"name": "park", "addr": "jeju"}'
@app.post("/members")
def save_members(member: MemberCreate):
    conn = psycopg2.connect(WRITABLE_URL)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # 1. name과 addr을 member 테이블에 저장 (num은 SERIAL 자동 증가)
        # 꿀팁: RETURNING * 를 쓰면 방금 INSERT 된 데이터를 바로 리턴받을 수 있습니다!
        cursor.execute(
            "INSERT INTO member (name, addr) VALUES (%s, %s) RETURNING *;",
            (member.name, member.addr)
        )
        new_member = cursor.fetchone()
        
        # 2. 쓰기(INSERT/UPDATE/DELETE) 작업은 반드시 commit()을 해야 DB에 반영됩니다!
        conn.commit()
        
    except Exception as e:
        # 에러 발생 시 롤백 후 500 에러 반환
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()
        
    # 3. 결과 응답
    return {"status": "success", "data": new_member}