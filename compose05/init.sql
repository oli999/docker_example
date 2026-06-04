-- init.sql 파일 

-- sample 테이블 
CREATE TABLE member(num SERIAL PRIMARY KEY, name VARCHAR(20), addr TEXT);
-- sample 데이터
INSERT INTO member (name, addr) VALUES('kim', 'seoul');
INSERT INTO member (name, addr) VALUES('lee', 'pusan');