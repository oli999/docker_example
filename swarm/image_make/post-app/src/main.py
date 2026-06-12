from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import psycopg2
from psycopg2.extras import RealDictCursor
import os

# swagger ui 가 /posts/docs 주소에서 사용될수 있도록 설정
app = FastAPI(
    docs_url="/posts/docs", 
    openapi_url="/posts/openapi.json",
    redoc_url=None 
)

# 환경변수 매핑 (프록시 쓰기: 5432, 읽기: 5433)
WRITABLE_URL = os.getenv("WRITABLE_URL", "postgresql://scott:tiger@localhost:5432/scott_db")
READONLY_URL = os.getenv("READONLY_URL", "postgresql://scott:tiger@localhost:5433/scott_db")

# POST, PUT 요청으로 들어올 JSON 데이터 규격 정의 (writer, title 만 입력받음)
class PostCreate(BaseModel):
    writer: str
    title: str

@app.get("/")
def read_root():
    return {"message": "hello, fastapi posts API!"}

# =====================================================================
# [READ] 전체 게시글 조회 (읽기 전용 DB - 5433 포트 사용)
# =====================================================================
@app.get("/posts")
def read_posts():
    conn = psycopg2.connect(READONLY_URL)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    # 글번호(num) 오름차순 정렬하여 전체 조회
    cursor.execute("SELECT * FROM posts ORDER BY num ASC;")
    rows = cursor.fetchall()
    
    cursor.close()
    conn.close()
    return {"status": "success", "data": rows}

# =====================================================================
# [READ] 단일 게시글 상세 조회 (읽기 전용 DB - 5433 포트 사용)
# =====================================================================
@app.get("/posts/{num}")
def read_post(num: int):
    conn = psycopg2.connect(READONLY_URL)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    cursor.execute("SELECT * FROM posts WHERE num = %s;", (num,))
    row = cursor.fetchone()
    
    cursor.close()
    conn.close()
    
    # 게시글이 존재하지 않을 경우 404 에러 반환
    if not row:
        raise HTTPException(status_code=404, detail="해당 게시글을 찾을 수 없습니다.")
        
    return {"status": "success", "data": row}

# =====================================================================
# [CREATE] 게시글 등록 (쓰기 전용 DB - 5432 포트 사용)
# =====================================================================
@app.post("/posts")
def save_post(post: PostCreate):
    conn = psycopg2.connect(WRITABLE_URL)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # 💡 주석: num과 created_at은 DB 내부에서 자동으로 세팅되므로 writer, title만 삽입
        cursor.execute(
            "INSERT INTO posts (writer, title) VALUES (%s, %s) RETURNING *;",
            (post.writer, post.title)
        )
        new_post = cursor.fetchone()
        conn.commit()
        
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()
        
    return {"status": "success", "data": new_post}

# =====================================================================
# [UPDATE] 게시글 정보 수정 (쓰기 전용 DB - 5432 포트 사용)
# =====================================================================
@app.put("/posts/{num}")
def update_post(num: int, post: PostCreate):
    conn = psycopg2.connect(WRITABLE_URL)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # 특정 글번호의 작성자와 제목을 수정하고 즉시 반환 받아 존재 여부 파악
        cursor.execute(
            "UPDATE posts SET writer = %s, title = %s WHERE num = %s RETURNING *;",
            (post.writer, post.title, num)
        )
        updated_post = cursor.fetchone()
        
        # 수정하려는 글번호가 존재하지 않으면 롤백 후 404 처리
        if not updated_post:
            conn.rollback()
            raise HTTPException(status_code=404, detail="수정할 게시글을 찾을 수 없습니다.")
            
        conn.commit()
        
    except HTTPException:
        raise 
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()
        
    return {"status": "success", "data": updated_post}

# =====================================================================
# [DELETE] 게시글 삭제 (쓰기 전용 DB - 5432 포트 사용)
# =====================================================================
@app.delete("/posts/{num}")
def delete_post(num: int):
    conn = psycopg2.connect(WRITABLE_URL)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # 삭제 후 RETURNING을 사용해 지워진 글의 정보를 최종 리턴받음
        cursor.execute(
            "DELETE FROM posts WHERE num = %s RETURNING *;",
            (num,)
        )
        deleted_post = cursor.fetchone()
        
        # 삭제하려는 글번호가 존재하지 않으면 롤백 후 404 처리
        if not deleted_post:
            conn.rollback()
            raise HTTPException(status_code=404, detail="삭제할 게시글을 찾을 수 없습니다.")
            
        conn.commit()
        
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()
        
    return {"status": "success", "data": deleted_post}