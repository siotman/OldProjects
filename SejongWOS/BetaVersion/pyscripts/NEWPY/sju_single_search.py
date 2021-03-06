import sju_utiles
import sju_models
import sju_CONSTANTS
import sju_exceptions

import re
import random
import requests
import threading
from datetime import datetime

from sju_utiles import os
from sju_utiles import UserAgent
from sju_utiles import BeautifulSoup

class SingleSearch():
    '''
        SingleSearch Class는 한 논문에 대한 상세기능을 제공
        이 Class는 start() 함수를 사용하여 검색된 한 논문의 관한 상세 정보를 보낸다.
        (연도별 인용횟수,IMPACT FACTOR,JCR 순위,연구기관 주소)
    '''
    def __init__(self, thread_id = None, cookies = None):
        '''
			SingleSearch constructor
            :param thread_id: 쓰레드 네임
            :Param cookies: 쿠키 값 변수
			:param session: 세션 변수
			:param base_url: 메인 도메인 URL
			:param res_name: push command 변수
			:param ui_stream: logging을 위한 함수 호출 후 저장
			:return:
        '''
        self.qid = 0
        self.session = False
        self.base_url = "http://apps.webofknowledge.com"
        self.res_name = 'res' if thread_id == None else 'mres'
        self.thread_id = 'single main' if thread_id == None else thread_id
        ui_stream_name = 'single_search' if thread_id == None else 'multi sub'
        self.ui_stream = sju_models.UI_Stream(ui_stream_name, self.thread_id, self.res_name)

        self.set_session(cookies)


    def set_session(self, cookies = None):
        '''
			세션 갱신 함수
			:param cookies: 쿠키 값 저장 변수
			:return:
        '''
        MAX_TRIES = 5
        self.qid = 0

        ui_stream = self.ui_stream

        tries = 0
        session = requests.Session()

        # SID와 JSESSIONID가 주어질 경우
        if cookies:
            session = sju_utiles.set_user_agent(session)
            session.cookies.update(cookies)
            self.SID = session.cookies['SID'].replace("\"", "")
            self.jsessionid = session.cookies['JSESSIONID']
            ui_stream.push(command='log', msg='SID : %s'%self.SID)
            ui_stream.push(command='log', msg='JSESSIONID : %s'%self.jsessionid)

        while tries < MAX_TRIES and not cookies:
            # 세션 갱신
            ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1001])
            session = sju_utiles.set_user_agent(session)
            # 세션 SID, JSESSIONID 요청
            ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1101])
            res = session.get('http://apps.webofknowledge.com', allow_redirects=False, verify=False)
            
            for redirect in session.resolve_redirects(res, res.request):
                if 'SID' in session.cookies.keys(): break

            # SID요청 에러 판별
            if res.status_code == requests.codes.FOUND or res.status_code == requests.codes.OK:
                if res.url.find('login') > -1:
                    raise sju_exceptions.LoginRequired()

                self.SID = session.cookies['SID'].replace("\"", "")
                self.jsessionid = session.cookies['JSESSIONID']
                
                ui_stream.push(command='log', msg='SID : %s'%self.SID)
                ui_stream.push(command='log', msg='JSESSIONID : %s'%self.jsessionid)

                # 요청 성공
                ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1201])
                break
            elif res.status_code == 403:
                # ui_stream.push(command='log', msg='스레드가 403 상태 메세지를 받았습니다.')
                tries += 1
                ui_stream.push(command='log', msg='서버에서 거부하여 2초 뒤 재시도합니다. [%d/%d]'%(tries, MAX_TRIES))
                continue
            else:
                # 요청 실패
                ui_stream.push(command='err', msg=sju_CONSTANTS.STATE_MSG[1301][0])
                raise sju_exceptions.InitSessionError()

        if tries >= MAX_TRIES:
            raise sju_exceptions.InitSessionError()

        if self.session: self.session.close()
        self.session = session

    def get_tc_data(self, report_link, paper_data_id, tc_data):
        '''
			인용보고서에서 인용년도를 조회하는 함수 (start() 함수에서 사용)
			:param report_link: 인용보고서 링크
            :param paper_data_id: 
            :param tc_data: 인용년도 연도별 데이터 저장
			:return:
        '''
        self.ui_stream.push(command='log', msg='인용년도 정보를 가져옵니다.')
        session = self.session
        current_year = datetime.today().year

        # [단계 2/3] 인용년도 조회 (병렬 구성)
        #########################################################################

        http_res = sju_utiles.sju_get(session, self.base_url + "/" + report_link, True, 5)
        #http_res = session.get(self.base_url + "/" + report_link, verify=False)
        target_content = http_res.content
        soup = BeautifulSoup(target_content, 'html.parser')

        raw_tc_data = soup.select_one('tr#PublicationYear_raMore_tr')

        tc_tuple_list = re.findall(r'20.. \(.+\)', raw_tc_data.text)
        tmp = ""
        for i in range(len(tc_tuple_list)):
            tmp += tc_tuple_list[i]

        tmp = tmp.replace(' ','')
        tmp = tmp.split(')')
        tmp.sort()
        
        tmp_tc_dict = {}
        for i in range(len(tmp)):
            if tmp[i] == "":
                continue
            a1 = tmp[i][:tmp[i].find('(')]
            a2 = tmp[i][tmp[i].find('(')+1:]
            tmp_tc_dict.update({a1: a2})
            
        print("tmp tc dict : ",tmp_tc_dict)

        tc_dict = {}
        # 빈 연도 0으로 채우기
        for y_now in range(current_year-9,current_year+1):
            try:
                if tmp_tc_dict[str(y_now)] != 0:
                    #print("already have data")
                    tc_dict.update({str(y_now): tmp_tc_dict[str(y_now)]})
            except:
                tc_dict.update({str(y_now): '0'})

        tc_data['tc_dict'] = tc_dict

    def get_one_tc_data(self, report_year, tc_data):
        self.ui_stream.push(command='log', msg='인용년도 정보를 가져옵니다.')
        current_year = datetime.today().year

        if report_year == 'zero':
            a1 = '0'
            a2 = '0'
        else:
            a1 = report_year[:report_year.find('(')]
            a2 = report_year[report_year.find('(')+1: report_year.find(')')]
        
        
        tc_dict = {}
        # 빈 연도 0으로 채우기
        for y_now in range(current_year-9,current_year+1):
            if str(y_now) == a1:
                tc_dict.update({a1: a2})
            else:
                tc_dict.update({str(y_now): '0'})
            
        tc_data['tc_dict'] = tc_dict


    def start(self, query, start_year, end_year, gubun):
        '''
			하나의 논문에 관한 상세 정보 제공함수
			:param query: keyword, p_authors, organization 각각 문자열 
			:param start_year: 시작년도
			:param end_year: 끝년도
			:param gubun: 검색 구분 카테고리
			:return:
        '''
        # Sejong Univ 로 고정
        #####################
        query = (query[0], query[1], 'Sejong Univ')

        # driver = self.driver
        session = self.session
        base_url = self.base_url
        ui_stream = self.ui_stream

        keyword = query[0]
        p_authors = query[1]
        organization = query[2]


        paper_data_id = str(random.getrandbits(32))

        # 검색속도 향상을 위한 헤더 랜더마이즈
        # orginal_headers = session.headers
        # session.headers.update({'User-Agent': str(random.getrandbits(32))})
        # [단계 1/3] 최초 검색
        #########################################################################
        ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1002])
        ui_stream.push(command='log', msg='검색어 : %s'%keyword)

        if keyword.find('=') != -1:
            ui_stream.push(command='err', msg=sju_CONSTANTS.STATE_MSG[1300][0])
            ui_stream.push(
                command='res', target='errQuery', 
                res={'query': query, 'msg': sju_CONSTANTS.STATE_MSG[1300][0]}
            )
            return

        action_url = '/WOS_GeneralSearch.do'
        form_data = {
            'action': 'search',
            'product': 'WOS',
            'search_mode': 'GeneralSearch',
            'sa_params': 'WOS||%s|http://apps.webofknowledge.com|\''%self.SID,
            'SID': self.SID,
            'value(input1)': keyword,
            'value(select1)': gubun,
            'startYear': start_year,
            'endYear': end_year,
        }
        if organization != '':
            form_data.update({
                'limitStatus': 'expanded',
                'value(bool_1_2)': 'AND',
                'value(input2)': organization,
                'value(select2)': 'AD',
                'fieldCount': '2',
            })
        
        # 검색 요청
        ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1102])

        url = base_url + action_url
        # SEJONG WIFI 접속 시 변수명에 특정 문자를 바르게 인코딩하지 못하는 현상
        # 어떤 문자인 지 찾아서 수정하는 작업이 필요.
        # form_data = sju_utiles.get_form_data(action_url, form_data)
        
        self.qid += 1
        http_res = sju_utiles.sju_post(session, url, form_data, 5, query)
        #http_res = session.post(url, form_data, verify=False)

        # # 검색 성공
        # if http_res.status_code == requests.codes.ok:
        #     location = http_res.history[0].headers['Location']
        #     reffer = base_url + '/' + location
        
        # # 검색 실패
        # else:
        #     ui_stream.push(command='err', msg=sju_CONSTANTS.STATE_MSG[1302][2])
        #     raise sju_exceptions.RequestsError

        # Access Denied
        if http_res.status_code == 403:
            ui_stream.push(
                command='res', target='errQuery', 
                res={'query': query, 'msg': '검색을 요청했으나 서버가 접근 권한 없음을 반환했습니다.'}
            )
            return

        # http_res = session.get(reffer)
        
        # # Access Denied
        # if http_res.status_code == 403:
        #     ui_stream.push(
        #         command='res', target='errQuery', 
        #         res={'query': query, 'msg': '결과 리스트 페이지를 요청했으나 서버가 접근 권한 없음을 반환했습니다.'}
        #     )
        #     return

        target_content = http_res.content
        soup = BeautifulSoup(target_content, 'html.parser')
        atag_list = soup.select('a.snowplow-full-record')

        #report_link = soup.select('a.citation-report-summary-link')

        try: 
            if len(atag_list) == 0:
                raise sju_exceptions.NoPaperDataError()
            elif len(atag_list) > 1:
                raise sju_exceptions.MultiplePaperDataError()
        # 검색 결과가 없을 경우
        except sju_exceptions.NoPaperDataError:
            ui_stream.push(command='err', msg=sju_CONSTANTS.STATE_MSG[1302][0])
            
            ui_stream.push(
                command='res', target='errQuery', 
                res={'query': query, 'msg': sju_CONSTANTS.STATE_MSG[1302][0]}
            )
            return
        # 검색 결과가 2개 이상일 경우
        except sju_exceptions.MultiplePaperDataError:
            ui_stream.push(command='err', msg=sju_CONSTANTS.STATE_MSG[1302][1])
            ui_stream.push(
                command='res', target='errQuery', 
                res={'query': query, 'msg': sju_CONSTANTS.STATE_MSG[1302][1]}
            )
            return
        except Exception as e:
            ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1303][0])
            raise Exception(e)

        ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1202])

        # [단계 2/3] 상세 정보 페이지 fetch, 인용년도 조회 (스레딩)
        #########################################################################
        ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1003])
        """
        tc_data = {'tc_dict': []}
        tc_parsing_thread = None
        # 인용 보고서 링크가 잡힐 때
        if len(report_link) != 0:
            # 인용년도 조회 스레딩
            tc_parsing_thread = threading.Thread(
                target=self.get_tc_data,
                args=(report_link, paper_data_id, tc_data)
            )
            tc_parsing_thread.start()
        """
        # 결과 리스트 페이지를 들렀다 오는 경우
        query_string = atag_list[0]['href']

        # # 상세 보기 바로 진입 하는 경우
        # # qid가 랜덤한 경우가 존재... 사용하기 위해선
        # # 이슈가 해결되야함.
        # action_url = '/full_record.do'
        # query_data = {
        #     'page': '1',
        #     'qid': str(self.qid),
        #     'SID': self.SID,
        #     'doc': '1',
        # }
        # query_string = sju_utiles.get_query_string(action_url, query_data)

        # 상세 정보 요청
        ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1103])
        
        # session.headers['Reffer'] = reffer
        
        http_res = sju_utiles.sju_get(session, base_url + query_string, False, 5, query)
        #http_res = session.get(base_url + query_string, verify=False)

        # Access Denied
        if http_res.status_code == 403:
            ui_stream.push(
                command='res', target='errQuery', 
                res={'query': query, 'msg': '해당 논문의 상세 정보를 요청했으나 서버가 접근 권한 없음을 반환했습니다.'}
            )
            return

        target_content = http_res.content

        # 상세 정보 파싱
        try:
            paper_data, cnt_link = sju_utiles.parse_paper_data(target_content, paper_data_id, "single", self.SID)
            # paper_data['subsidy'] = sju_utiles.get_subsidy01(paper_data, p_authors)

        # 검색 결과가 없을 경우
        except sju_exceptions.NoPaperDataError:
            ui_stream.push(command='err', msg=sju_CONSTANTS.STATE_MSG[1302][0])
            ui_stream.push(
                command='res', target='errQuery', 
                res={'query': query, 'msg': sju_CONSTANTS.STATE_MSG[1302][0]}
            )
            return
        # 검색 결과가 2개 이상일 경우
        except sju_exceptions.MultiplePaperDataError:
            ui_stream.push(command='err', msg=sju_CONSTANTS.STATE_MSG[1302][1])
            ui_stream.push(
                command='res', target='errQuery', 
                res={'query': query, 'msg': sju_CONSTANTS.STATE_MSG[1302][1]}
            )
            return
        except Exception as e:
            ui_stream.push(command='err', msg=sju_CONSTANTS.STATE_MSG[1302][2])
            ui_stream.push(
                command='res', target='errQuery', 
                res={'query': query, 'msg': sju_CONSTANTS.STATE_MSG[1302][2]}
            )
            # raise sju_exceptions.FailedToParseError(e, query)
            return
        # 요청 성공
        else:
            ui_stream.push(command='res', target='paperData', res=paper_data)
            ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1203])
            # 인용 년도 조회 완료를 기다림
            #if tc_parsing_thread:
            #    tc_parsing_thread.join()
            #    ui_stream.push(command='log', msg='인용 년도 조회가 완료되었습니다.')

            #tc_dict = tc_data['tc_dict']
            # 인용 년도 조회 성공 시 출력
            #if len(tc_dict) > 0:
                #ui_stream.push(command='res', target='tc_data', res={'id': paper_data_id, 'tc_data': tc_dict})
            
            
        # # 요청 실패
        

        # [단계 3/3] 인용 논문 정보
        #########################################################################
        ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1004])
        
        # 인용 횟수에 따른 분기
        test_check = 0
        if not cnt_link:
            ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1304][0])
            self.qid += 1
            test_check = 1
        elif int(paper_data['timesCited']) > 4999:
            ui_stream.push(command='err', msg=sju_CONSTANTS.STATE_MSG[1304][1])
            ui_stream.push(
                command='res', target='errQuery', 
                res={'query': query, 'msg': sju_CONSTANTS.STATE_MSG[1304][1]}
            )
            self.qid += 1
            return

        # 인용 리포트 요청
        tc_data = {'tc_dict': []}
        if test_check == 0:
            ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[4104])

            url = base_url + cnt_link['href']
            http_res = sju_utiles.sju_get(session, url, True, 5, query)
            #http_res = session.get(url, verify=False)

            # Access Denied
            if http_res.status_code == 403:
                ui_stream.push(
                    command='res', target='errQuery', 
                    res={'query': query, 'msg': '인용 리포트를 요청했으나 서버가 접근 권한 없음을 반환했습니다.'}
                )
                return

            target_content = http_res.content

            soup = BeautifulSoup(target_content, 'html.parser')

            # 인용문 링크는 존재하나, 클릭할 경우 검색 결과가 없다는 메세지가 뜰 때
            if  soup.text.find('Your search found no records') != -1 or soup.text.find('None of the Citing Articles are in your subscription') != -1:
                self.get_one_tc_data('zero', tc_data)
                tc_dict = tc_data['tc_dict']
                ui_stream.push(command='res', target='tc_data', res={'id': paper_data_id, 'tc_data': tc_dict})
                """
                ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[4304][3])
                ui_stream.push(
                    command='res', target='errQuery', 
                    res={'query': query, 'msg': sju_CONSTANTS.STATE_MSG[4304][3]}
                )
                """
                return
        
        # 연도별 인용 횟수 가져오기 (NEW PART)
        if cnt_link:
            try:
                year_url = soup.select('a#PublicationYear')[0].attrs['href']
                self.get_tc_data(year_url, paper_data_id, tc_data)
                #print("======================================================")
                #print("tc_data[1] : ",tc_data)
                #print("======================================================")
            except:
                # 만약 인용 횟수가 한 연도만 존재할 때
                year_url = soup.select('div#PublicationYear_tr')[0]
                year_url = year_url.select_one('label.ra-summary-text').text
                year_url = year_url.replace(' ','')
                self.get_one_tc_data(year_url, tc_data)
                #print("======================================================")
                #print("tc_data[2] : ",tc_data)
                #print("======================================================")
        # 인용횟수가 없을 경우 > 인용 정보를 0으로 초기화
        else:
            ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[4304][0])
            self.get_one_tc_data('zero', tc_data)
            #print("======================================================")
            #print("tc_data[3] : ",tc_data)
            #print("======================================================")
        
        tc_dict = tc_data['tc_dict']
        # 인용 년도 조회 성공 시 출력
        ui_stream.push(command='res', target='tc_data', res={'id': paper_data_id, 'tc_data': tc_dict})
        
        if test_check == 1:
            return
        
        ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1104])

        qid = soup.select('input#qid')[0].attrs['value']
        rurl = soup.select('input#rurl')[0].attrs['value']
        times_cited = paper_data['timesCited']
        self.qid = int(qid)

        # Fast 5000 요청 및 다운로드
        ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1204])

        action_url = '/OutboundService.do?action=go&&'
        form_data = {
            'qid': str(self.qid),
            'SID': self.SID,
            'mark_to': times_cited,
            'markTo': times_cited,
        }
        form_data = sju_utiles.get_form_data(action_url, form_data)

        url = base_url + action_url
        http_res = sju_utiles.sju_post(session, url, form_data, 5, query)
        #http_res = session.post(url, form_data, verify=False)
        self.qid += 1

        # Access Denied
        if http_res.status_code == 403:
            ui_stream.push(
                command='res', target='errQuery', 
                res={'query': query, 'msg': '인용 논문 자료 다운로드를 요청했으나 서버가 접근 권한 없음을 반환했습니다.'}
            )
            return

        # Fast 5000 데이터 처리
        ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1404])

        fast_5000 = http_res.content.decode('utf-8').replace('\r', '')
        fast_5000_list = fast_5000.split('\n')
        keys = fast_5000_list[0].split('\t')
        fast_5000_list = fast_5000_list[1:]
        if fast_5000_list[-1] == '': fast_5000_list.pop()

        article = {}
        citing_articles = []
        for row in fast_5000_list:
            row_list = row.split('\t')
            for idx, key in enumerate(keys):
                article[key] = row_list[idx]
            citing_articles.append(article)
            article = {}

        # UI 응답 형식에 맞게 변환
        citingArticles = {'id': paper_data['id'], 'selfCitation': 0, 'othersCitation': 0, 'titles': [], 'authors': [], 'isSelf': []}

        # 기준 저자 검증
        if p_authors != '':
            ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1504])
            p_authors = list(map(lambda x: x.replace(' ', '').replace(',', ''), p_authors.split(';')))

        for article in citing_articles:
            citingArticles['titles'] += [article['TI']]
            citingArticles['authors'] += [article['AU']]
            au_temp = article['AU'].replace(' ', '').replace(',', '')
            if p_authors != '':
                found = False
                for pa in p_authors:
                    if re.search(pa, au_temp, flags=re.IGNORECASE):
                        found = True
                        citingArticles['selfCitation'] += 1
                        citingArticles['isSelf'] += ['Self']
                        break

                if not found:
                    citingArticles['othersCitation'] += 1
                    citingArticles['isSelf'] += ['Others\''] 
            else:
                citingArticles['isSelf'] += ['-']

        ui_stream.push(command='res', target='citingArticles', res=citingArticles)

        # [단계 종료] 단일 상세 검색
        #########################################################################
        # history 제한 방지
        if self.qid > 180:
            self.set_session()
        
        ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1200][0])

        return


        # # 필요할 경우 사용
        # # Fast 5000 다운로드 +
        # self.qid += 1
        # action_url = '/ETS/ets.do'
        # query_data = {
        #     'mark_from': '1',               # required
        #     'parentQid': self.qid,          # required
        #     'rurl': rurl,                   # required
        #     'mark_to': '',                  # required
        #     'rid': 'U-9523-2018',           # required_optional
        #     'qid': qid,                     # required
        #     'SID': self.SID,                # required
        #     'totalMarked': times_cited,     # required
        #     'action': 'crsaveToFile',       # required
        #     'fileOpt': 'xls',               # required
        #     'UserIDForSaveToRID': '10957580', # required_optional
        # }

        # query_string = sju_utiles.get_query_string(action_url, query_data)

        # url = base_url + query_string
        # http_res = session.get(url)

        # ui_stream.push(command='log', msg=sju_CONSTANTS.STATE_MSG[1204])


# if __name__ == "__main__":
#     ss = SingleSearch()
#     ss.start(
#         ('없는데이터', '', '')
#         ,'2000','2018','TI'
#     )

# if __name__ == "__main__":
#     ss = SingleSearch()
#     ss.start(
#         ('asd', '', '')
#         ,'2000','2018','TI'
#     )

# if __name__ == "__main__":
#     ss = SingleSearch()
#     ss.start(
#         ('Mathematical Modeling of Nitric Oxide Diffusion in Small Arterioles', '', '')
#         ,'2000','2018','TI'
#     )

if __name__ == "__main__":
    ss = SingleSearch()
    print('입력바람')
    while(True):
        """
        ss.start(
            (input(), input(), input())
            ,'1945',
            '2018',
            'TI'
        )
        """
        ss.start(
            ('A military history of the ancient world: retrospective prospective', '', 'Sejong Univ'),
            '1945',
            '2018',
            'TI'
        )
        
