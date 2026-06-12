-- init.sql 파일 내용

-- 만일 member 테이블이 존재하지 않으면 테이블을 생성하고 셈플 데이터를 넣는 내용
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'member') THEN
        -- 테이블 생성
        CREATE TABLE member(num SERIAL PRIMARY KEY, name VARCHAR(20), addr TEXT);
        -- samle 데이터 넣기 
        INSERT INTO member (name, addr) VALUES('kim', 'seoul');
        INSERT INTO member (name, addr) VALUES('lee', 'pusan');
    END IF;
END $$;

DO $$ 
BEGIN
    -- posts 테이블이 존재하는지 확인
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'posts') THEN
        -- 테이블 생성 (created_at은 기본값으로 현재 시간이 자동 저장되도록 설정)
        CREATE TABLE posts(
            num SERIAL PRIMARY KEY, 
            writer VARCHAR(50), 
            title VARCHAR(255), 
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        -- sample 데이터 넣기 (num과 created_at은 자동 생성되므로 생략 가능!)
        INSERT INTO posts (writer, title) VALUES('kim', '첫 번째 게시글입니다.');
        INSERT INTO posts (writer, title) VALUES('lee', '안녕하세요, 가입인사 드립니다.');
    END IF;
END $$;