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