
import { FIELD, PaperRecordContainer, CRITERIA } from '../../../public/apis/api/paper-api.js'
import { WokSearchClient } from '../../../public/apis/api/wos-api'

const state = {
  memberPaper: {},
  searchPaperOnWOS: {},
  apiObject: {},
  WOSObject: {},
  searchPaperPage: 0,
  memberPaperPage: null,

  // refactoring
  componentFlag: 1, // component 전환 flag ( 1: search my paper / 2: paper statics / 3: paper edit )
  searchFlag: 0,
  optionByComponent : [[],                              // 0: empty
    [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 18],      // 1: option for search my paper
    [3, 4, 5, 6, 7, 8, 9, 13, 10, 15, 17, 18, 1, 2, 0], // 2: option for paper statics
    [1, 3, 4, 6, 7, 9]],                                // 3: option for paper edit
  endPage: -1,
  citeCounter: 0
}

const getters = {
  MEMBER_OBJECT_GETTER (state) {
    return state.apiObject
  },
  WOS_OBJECT_GETTER (state) {
    return state.WOSObject
  },
  SEARCH_PAGE_GETTER (state) {
    return state.searchPaperPage
  },
  MEMBER_PAGING_COUNT_GETTER (state) {
    return state.memberPaperPage
  },
  SEARCH_ON_WOS_GETTER (state) {
    return state.searchPaperOnWOS
  },
  CITE_COUNTER_GETTER (state) {
    return state.citeCounter
  },
  END_PAGE_GETTER (state){
    return state.endPage
  },

  // refactoring
  PAGE_FLAG_GETTER (state){
    return state.componentFlag
  },
  SEARCH_FLAG_GETTER (state){
    return state.searchFlag
  },
  MEMBER_PAPER_GETTER (state) {
    return state.memberPaper
  },
}

const mutations = {
  MEMBER_OBJECT_SET_MUTATION (state) {
    const token = sessionStorage.getItem('token')
    const Session = JSON.parse(sessionStorage.getItem('data'))
    state.apiObject = new PaperRecordContainer(Session.username, token, 'http://www.siotman.com:9401/')
  },
  WOS_OBJECT_SET_MUTATION (state) {
    const SERVER_URL = 'http://www.siotman.com:9400/'
    state.WOSObject = new WokSearchClient(SERVER_URL)
  },
  MEMBER_PAPER_MUTATION (state, payload) {
    const criteria = { field: FIELD.TITLE, operation: CRITERIA.LIKE, value: ' ' }
    state.apiObject.listByPage(1, 10, FIELD.TITLE, true, [criteria]).then(res => {
      state.memberPaper = state.apiObject.getRecords(payload)
      console.log(payload)
    }).catch(error => {
      console.log(error)
    })
  },


  SEARCH_ON_WOS_MUTATION (state, payload) {
    state.searchPaperOnWOS = payload
  },
  SEARCH_PAGING_MUTATION (state, payload) {
    state.searchPaperPage = payload
  },
  MEMBER_PAGING_MUTATION (state, payload) {
    state.memberPaper = payload
  },
  MEMBER_PAGING_COUNT_MUTATION (state) {
    state.memberPaperPage = state.apiObject.getPageState().endPage
  },
  CITE_COUNT_MUTATION (state, payload) {
    state.citeCounter = payload
  },
  CLEAR_STORE_MUTATION (state) {
    state.memberPaper = {}
    state.searchPaperOnWOS = {}
    state.apiObject = {}
  },
  // refactoring
  SET_PAGE_MUTATION (state, page){
    state.componentFlag = page
  },
  SET_SEARCH_FLAG_MUTATION (state){
    state.searchFlag = 0
  },
  NEW_MEMBER_PAPER_MUTATION (state, {count, orderBy, criteria} ){
    state.apiObject.listByPage(1, count, orderBy, true, criteria).then(res => {
      state.memberPaper = state.apiObject.getRecords(state.optionByComponent[state.componentFlag])
    }).catch(error => {
      console.log(error)
    })
  }, // 넘겨받은 조건으로 첫 페이지 불러오기
  MEMBER_PAPER_PAGING_MUTATION (state, page) {
    state.apiObject.retrive(page).then(res => {
      state.memberPaper = state.apiObject.getRecords(state.optionByComponent[state.componentFlag])
      return 1
    }).catch(error => {
      console.log(error)
    })
  },
  SEARCH_MY_PAPER_MUTATION (state, criteria){
    state.searchFlag = 1
    state.apiObject.listByPage(1, 10, FIELD.TITLE, true, criteria).then(res => {
      state.memberPaper = state.apiObject.getRecords(state.optionByComponent[state.componentFlag])
    }).catch(error => {
      console.log(error)
    })
  },
  SET_END_PAGE_MUTATION (state, {count, criteria}) {

    state.apiObject.listByPage(1, count, FIELD.TITLE, true, criteria).then(res => {
      state.endPage = state.apiObject.getPageState().endPage + 1
    }).catch(error => {
      console.log(error)
    })
  },
  ALL_PAPER_MUTATION (state, {count, criteria}) {
    let page = 1
    state.memberPaper = []
    while(state.endPage > page){
      state.apiObject.listByPage(page, 10, FIELD.TITLE, true, criteria).then(res => {
        state.memberPaper.push(state.apiObject.getRecords(state.optionByComponent[state.componentFlag]))
        console.log('hi',state.memberPaper)
      }).catch(error => {
        console.log(error)
      })
      page += 1
    }
  },
}

const actions = {
  MEMBER_OBJECT_SET_ACTION (context) {
    context.commit('MEMBER_OBJECT_SET_MUTATION')
  }, // api 객체 생성 action
  WOS_OBJECT_SET_ACTION (context) {
    context.commit('WOS_OBJECT_SET_MUTATION')
  }, // WOS api 객체 생성 action
  MEMBER_PAPER_ACTION (context, payload) {
    context.commit('MEMBER_PAPER_MUTATION', payload)
  },


  SEARCH_ON_WOS_ACTION (context, payload) {
    context.commit('SEARCH_ON_WOS_MUTATION', payload)
  },
  SEARCH_PAGING_ACTION (context, payload) {
    context.commit('SEARCH_PAGING_MUTATION', payload)
  },
  MEMBER_PAGING_ACTION (context, payload) {
    context.commit('MEMBER_PAGING_MUTATION', payload)
  },
  MEMBER_PAGING_COUNT_ACTION (context) {
    context.commit('MEMBER_PAGING_COUNT_MUTATION')
  },
  CITE_COUNT_ACTION (context, payload) {
    context.commit('CITE_COUNT_MUTATION', payload)
  },
  SEARCH_MY_PAPER_ACTION (context, criteria){
    context.commit('SEARCH_MY_PAPER_MUTATION', criteria)
  },
  CLEAR_STORE_ACTION (context) {
    context.commit('CLEAR_STORE_MUTATION')
  }, // 로그아웃시 스토어 클리어 action

  // refactoring
  SET_PAGE_ACTION (context, page) {
    context.commit('SET_PAGE_MUTATION', page)
  },
  SET_SEARCH_FLAG_ACTION(context) {
    context.commit('SET_SEARCH_FLAG_MUTATION')
  },
  NEW_MEMBER_PAPER_ACTION (context, {count, orderBy, criteria}){
    context.commit('NEW_MEMBER_PAPER_MUTATION', {count, orderBy, criteria})
  },
  MEMBER_PAPER_PAGING_ACTION (context, page ) {
    context.commit('MEMBER_PAPER_PAGING_MUTATION', page)
  }, // 내 논문 불러오기
  SET_END_PAGE_ACTION (context, {count, criteria}){
    context.commit('SET_END_PAGE_MUTATION', {count, criteria})
  },
  ALL_PAPER_ACTION (context,  {count, criteria}) {
    context.commit('ALL_PAPER_MUTATION', {count, criteria})
  }, // 내 논문 불러오기

}
export default {
  state,
  mutations,
  actions,
  getters
}
