-- SQL 2.0 ver 06/01
/*
 * 디폴트 SQL
 */
-- 2017/06/09 불필요한 sql문 삭제

-- DROP ALL
DROP TABLE COMMENT_LIKE;
DROP TABLE QUESTION;
DROP TABLE DELIVERY_MATCH;
DROP TABLE APPLICATION;
DROP TABLE G_PRODUCT;
DROP TABLE LOC_COMMENT_PICTURE;
DROP TABLE LOC_COMMENT_REPLY;
DROP TABLE LOC_COMMENT;
DROP TABLE G_BOARD;
DROP TABLE VISIT;
DROP TABLE DELIVERY;
DROP TABLE REPORT;
DROP TABLE AUTOSEARCH;
DROP TABLE authorities;
DROP TABLE GD_MEMBER;

-- TABLES
-- 회원 테이블
CREATE TABLE GD_MEMBER(
	ID VARCHAR2(30) PRIMARY KEY,
	NAME VARCHAR2(18) NOT NULL,
	PASSWORD VARCHAR2(100) NOT NULL,
	ADDR VARCHAR2(100) NOT NULL,
	ADDR_DETAIL VARCHAR2(100) NOT NULL,
	TEL VARCHAR2(100) NOT NULL,
	JOB VARCHAR2(18) NOT NULL,
	--DELETEMEMBER VARCHAR2(100) DEFAULT 'TRUE',
	enabled number default 1, 
	IS_CONFIRMED VARCHAR2(100) DEFAULT 'NO'
);

create table authorities(
	id varchar2(100) not null,
	authority varchar(30) not null,
	constraint fk_authorities foreign key(id) references GD_MEMBER(id),
	constraint member_authorities primary key(id,authority)
);

--관리자 DB 주입
INSERT INTO GD_MEMBER(ID,NAME,PASSWORD,ADDR,ADDR_DETAIL,TEL,JOB,ENABLED,IS_CONFIRMED)
VALUES('admin','임진우','1234','경기도 광주시 회덕길','상세주소','01012341234','코스타',1,'NO');
INSERT INTO authorities(ID,AUTHORITY) VALUES('admin','ROLE_ADMIN');

-- 물려줄 물건 게시 단위 테이블
CREATE TABLE G_BOARD(
	BNO NUMBER PRIMARY KEY,
	TITLE VARCHAR2(50) NOT NULL,
	HIT NUMBER NOT NULL,
	TIME_POSTED DATE NOT NULL,
	ID VARCHAR2(30) NOT NULL,
	ADDR VARCHAR2(100) NOT NULL,
	BCONTENT CLOB NOT NULL,
	THUMBPATH VARCHAR2(100) NOT NULL,
	IS_TRADED VARCHAR2(10) DEFAULT 'WAITING',
	IS_DELETED VARCHAR2(10) DEFAULT 'NO',
	CONSTRAINT FK_BD_ID FOREIGN KEY(ID) REFERENCES GD_MEMBER ON DELETE CASCADE
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
	PICNO NUMBER NOT NULL,
	CONSTRAINT FK_COM_ID FOREIGN KEY(ID) REFERENCES GD_MEMBER ON DELETE CASCADE
);

CREATE TABLE LOC_COMMENT_PICTURE(
	IMG_PATH VARCHAR2(100) PRIMARY KEY,
	PICNO NUMBER NOT NULL,
	PIC_CURSOR NUMBER NOT NULL
);
-- 물려줄 물건 테이블
CREATE TABLE G_PRODUCT(
	PNO NUMBER PRIMARY KEY,
	PTITLE VARCHAR2(50) NOT NULL,
	BNO NUMBER  NOT NULL,
	KIND VARCHAR2(50) NOT NULL,
	PCONTENT CLOB NOT NULL,
	IMG_PATH VARCHAR2(100) NOT NULL,
	IS_TRADED VARCHAR2(50) DEFAULT 'FALSE',
	CONSTRAINT FK_BNO FOREIGN KEY(BNO) REFERENCES G_BOARD ON DELETE CASCADE
);

-- 신청서 테이블
CREATE TABLE APPLICATION(
   BNO NUMBER NOT NULL,
   REASON VARCHAR2(100) NOT NULL,
   PNOS VARCHAR2(100) NOT NULL,
   ID VARCHAR2(30) NOT NULL,
   IS_SELECTED VARCHAR2(10) DEFAULT 'WAITING', -- 기부자가 신청 채택시 selected
   IS_DELIVERY VARCHAR2(10) DEFAULT 'NO', -- 직거래일시 no,용달일 경우 yes
   IS_DONE VARCHAR2(50) DEFAULT 'NO',
   PRIMARY KEY(BNO,ID),
   CONSTRAINT FK_APP_ID FOREIGN KEY(ID) REFERENCES GD_MEMBER ON DELETE CASCADE,
   CONSTRAINT FK_APP_BNO FOREIGN KEY(BNO) REFERENCES G_BOARD ON DELETE CASCADE
   );
   
--댓글 테이블
CREATE TABLE LOC_COMMENT_REPLY(
	RNO NUMBER PRIMARY KEY,
	CNO NUMBER NOT NULL,
	ID VARCHAR2(30) NOT NULL,
	NAME VARCHAR2(30) NOT NULL,
	TIME_POSTED DATE NOT NULL,
	PARENT NUMBER DEFAULT 0,
	CONTENT CLOB NOT NULL,
	GNO NUMBER NOT NULL,
	DEPTH NUMBER DEFAULT 0,
	ORDER_NO NUMBER DEFAULT 1,
	CONSTRAINT FK_REP_CNO FOREIGN KEY(CNO) REFERENCES LOC_COMMENT ON DELETE CASCADE,
	CONSTRAINT FK_REP_ID FOREIGN KEY(ID) REFERENCES GD_MEMBER ON DELETE CASCADE
);

-- 방문자 카운트 테이블
CREATE TABLE VISIT (
	ID VARCHAR(30) NOT NULL,
	DAY VARCHAR(15) NOT NULL,
	COUNT NUMBER DEFAULT 0,
	PRIMARY KEY(ID, DAY)
);

--용달 맷칭 
CREATE TABLE DELIVERY_MATCH(
   BNO NUMBER NOT NULL,
   AID VARCHAR2(30) NOT NULL,
   DID VARCHAR2(30) NOT NULL,
   STATE VARCHAR2(100) DEFAULT 'WAITING',
   PRIMARY KEY(BNO, AID, DID),
   CONSTRAINT FK_MAT_BNO FOREIGN KEY(BNO) REFERENCES G_BOARD ON DELETE CASCADE,
   CONSTRAINT FK_MAT_DID FOREIGN KEY(AID) REFERENCES GD_MEMBER(ID) ON DELETE CASCADE,
   CONSTRAINT FK_MAT_AID FOREIGN KEY(DID) REFERENCES GD_MEMBER(ID) ON DELETE CASCADE
   -- did -> 용달id
);

--신고 관리
CREATE TABLE REPORT(
	REPORT_NO NUMBER PRIMARY KEY,
	CATEGORY VARCHAR2(30) NOT NULL,
	RENO NUMBER NOT NULL,
	ID VARCHAR2(30) NOT NULL,
	REPORTER VARCHAR2(30) NOT NULL,
	WHY CLOB NOT NULL,
	TIME_POSTED DATE NOT NULL,
	PROCESS VARCHAR2(30) DEFAULT 'FALSE',
	CONSTRAINT FK_REPORT_ID FOREIGN KEY(ID) REFERENCES GD_MEMBER(ID) ON DELETE CASCADE
);

-- 검색 자동 완성
CREATE TABLE AUTOSEARCH(
	KEYWORD VARCHAR2(100) PRIMARY KEY
);

CREATE TABLE QUESTION(
	QNO NUMBER PRIMARY KEY,-- Q&A 글번호
	TITLE VARCHAR2(50) NOT NULL,
	HIT NUMBER NOT NULL,
	TIME_POSTED DATE NOT NULL,
	ID VARCHAR2(30) NOT NULL, -- 작성자 아이디
	CONTENT CLOB NOT NULL,
	IS_SECRET NUMBER DEFAULT 1 NOT NULL, -- 비밀글 체크 여부
	RE_REF NUMBER NOT NULL, -- 글 그룹번호
	Q_PARENT NUMBER DEFAULT 0, --부모글 번호
	CONSTRAINT FK_QUESTION_ID FOREIGN KEY(ID) REFERENCES GD_MEMBER ON DELETE CASCADE
);
CREATE TABLE COMMENT_LIKE(
	LNO NUMBER PRIMARY KEY, --LIKE NO
	CNO NUMBER NOT NULL,
	ID VARCHAR2(30) NOT NULL,
	CONSTRAINT FK_COMMENT_LIKE_ID FOREIGN KEY(ID) REFERENCES GD_MEMBER ON DELETE CASCADE,
	CONSTRAINT FK_COMMENT_LIKE_CNO FOREIGN KEY(CNO) REFERENCES LOC_COMMENT ON DELETE CASCADE
);
-- SEQUENCES
DROP SEQUENCE Q_SEQ;
DROP SEQUENCE B_SEQ;
DROP SEQUENCE P_SEQ;
DROP SEQUENCE C_SEQ;
DROP SEQUENCE CR_SEQ;
DROP SEQUENCE RE_SEQ;
DROP SEQUENCE PIC_SEQ;
DROP SEQUENCE CL_SEQ;
-- B : BOARD / T : TRANSACTION / P : PRODUCT / A : APPLICATION / C : COMMENT / CR: COMMENT_REPLY / RE : REPORT
-- Q : QUESTION / CL : COMMENT_LIKE
CREATE SEQUENCE Q_SEQ;
CREATE SEQUENCE B_SEQ;
CREATE SEQUENCE P_SEQ;
CREATE SEQUENCE C_SEQ;
CREATE SEQUENCE CR_SEQ;
CREATE SEQUENCE RE_SEQ;
CREATE SEQUENCE PIC_SEQ;
CREATE SEQUENCE CL_SEQ;

