-- SQL 1.2 ver 05/23
/*
 * 디폴트 SQL
 * 1.2 컬럼 오류 수정
 */
-- DROP ALL
DROP TABLE APPLICATION;
DROP TABLE TRANSACTION;
DROP TABLE G_PRODUCT;
DROP TABLE LOC_COMMENT;
DROP TABLE G_BOARD;
DROP TABLE GD_MEMBER;

-- TABLES
-- 회원 테이블
CREATE TABLE GD_MEMBER(
	ID VARCHAR2(30) PRIMARY KEY,
	NAME VARCHAR2(18) NOT NULL,
	PASSWORD VARCHAR2(30) NOT NULL,

	ADDR VARCHAR2(50) NOT NULL,
	ADDR_DETAIL VARCHAR2(100) NOT NULL,
	TEL VARCHAR2(18) NOT NULL,
	JOB VARCHAR2(18) NOT NULL
);
INSERT INTO GD_MEMBER (ID,PASSWORD,NAME,ADDR,ADDR_DETAIL,TEL,JOB)
		VALUES('JAVA','1234','아이유','경기','판교','01085175486','학생')

-- 물려줄 물건 게시 단위 테이블
CREATE TABLE G_BOARD(
	BNO NUMBER PRIMARY KEY,
	TITLE VARCHAR2(50) NOT NULL,
	HIT NUMBER NOT NULL,
	TIME_POSTED DATE NOT NULL,
	ID VARCHAR2(30) NOT NULL,
	CONSTRAINT FK_BD_ID FOREIGN KEY(ID) REFERENCES GD_MEMBER
);

-- 지역 후기 테이블
CREATE TABLE LOC_COMMENT(
	CNO NUMBER PRIMARY KEY,
	TITLE VARCHAR2(50) NOT NULL,
	HIT NUMBER NOT NULL,
	TIME_POSTED DATE NOT NULL,
	ADDR VARCHAR2(100) NOT NULL,
	ID VARCHAR2(30) NOT NULL,
	CONTENT CLOB NOT NULL,
	CONSTRAINT FK_COM_ID FOREIGN KEY(ID) REFERENCES GD_MEMBER
);

-- 물려줄 물건 테이블
CREATE TABLE G_PRODUCT(
	PNO NUMBER PRIMARY KEY,
	PTITLE VARCHAR2(50) NOT NULL,
	BNO NUMBER  NOT NULL,
	KIND VARCHAR2(50) NOT NULL,
	PCONTENT VARCHAR2(50) NOT NULL,
	CONSTRAINT FK_BNO FOREIGN KEY(BNO) REFERENCES G_BOARD
);

-- 신청 내역 테이블
CREATE TABLE TRANSACTION(
	TNO NUMBER PRIMARY KEY,
	ID VARCHAR2(30) NOT NULL,
	CONSTRAINT FK_TRAN_ID FOREIGN KEY(ID) REFERENCES GD_MEMBER
);

-- 신청서 테이블
CREATE TABLE APPLICATION(
	ANO NUMBER PRIMARY KEY,
	REASON VARCHAR2(100) NOT NULL,
	ID VARCHAR2(30) NOT NULL,
	TNO NUMBER NOT NULL,
	CONSTRAINT FK_APP_TNO FOREIGN KEY(TNO) REFERENCES TRANSACTION,	
	CONSTRAINT FK_APP_ID FOREIGN KEY(ID) REFERENCES GD_MEMBER
);


-- SEQUENCES
DROP SEQUENCE B_SEQ;
DROP SEQUENCE T_SEQ;
DROP SEQUENCE P_SEQ;
DROP SEQUENCE A_SEQ;
DROP SEQUENCE C_SEQ;

-- B : BOARD / T : TRANSACTION / P : PRODUCT / A : APPLICATION / C : COMMENT
CREATE SEQUENCE B_SEQ;
CREATE SEQUENCE T_SEQ;
CREATE SEQUENCE P_SEQ;
CREATE SEQUENCE A_SEQ;
CREATE SEQUENCE C_SEQ;

-- SELECT
SELECT * FROM GD_MEMBER;
SELECT * FROM LOC_COMMENT;

-- TEST MEMBER
INSERT INTO GD_MEMBER(ID, NAME, PASSWORD, ADDR, ADDR_DETAIL, TEL, JOB) VALUES('java', '딘딘', '1234', '경기도 성남시 분당구', '삼평동 670','01012345678','취준생');

-- TEST COMMENT
insert into LOC_COMMENT(CNO, TITLE, HIT, TIME_POSTED, ADDR, ID, CONTENT) VALUES(C_SEQ.nextval, 'test1', '0', sysdate, '경기도 성남시 분당구', 'java', '내용');
insert into LOC_COMMENT(CNO, TITLE, HIT, TIME_POSTED, ADDR, ID, CONTENT) VALUES(C_SEQ.nextval, 'test2', '0', sysdate, '경기도 광주시 회덕동', 'java', '내용');

select * from (select cno, title, hit, time_posted, addr, id, content, row_number() over(order by cno desc) as rnumber from
		loc_comment) where rnumber between 1 and 5;
		
select * from LOC_COMMENT;
