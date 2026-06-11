-- init.sql 파일 내용
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