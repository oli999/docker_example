## src/main.py

# app.py
from fastapi import FastAPI
import psycopg2
from psycopg2.extras import RealDictCursor
import os

app = FastAPI()

"""
    환경변수에 있는 값을 os.getenv() 를 이용해서 얻어낼수가 있다. 

    os.getenv(<환경변수명> , <해당 환경변수가 없을때 default 로 사용할 값>)

    개발환경에서는 환경변수 없이 개발환경에 맞는 db 접속 url 을 기본값으로 넣어서 사용하면 된다.

    docker container 를 실행할때 아래와 같은 형식으로 환경변수를 전달할 예정이다 
    
    docker run -e DB_URL=postgresql://scott:tiger@<db 컨테이너의 이름>:5432/scott_db
    docker run -e DB_URL=postgresql://scott:tiger@my-postgres:5432/scott_db
"""
DB_URL = os.getenv("DB_URL", "postgresql://scott:tiger@localhost:5432/scott_db")

@app.get("/members")
def get_members():
    # 데이터베이스 장부 연결 및 커서 개설 (딕셔너리 형태로 변환 래핑)
    conn = psycopg2.connect(DB_URL)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    # member 레코드 긁어오기
    cursor.execute("SELECT * FROM member;")
    rows = cursor.fetchall()
    
    cursor.close()
    conn.close()
    return {"status": "success", "data": rows}