package controller;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import exception.SessionExpiredException;
import model.MemberDAO;
import model.MemberVO;

public class GetModifyController implements Controller {
   @Override
   public String execute(HttpServletRequest request, HttpServletResponse response) throws Exception {
	   HttpSession session = request.getSession();
		if(session==null||session.getAttribute("mvo")==null){
			throw new SessionExpiredException();
		}
      String password=request.getParameter("password");
      String id = request.getParameter("id");
      String name=request.getParameter("name");
      int limit=Integer.parseInt(request.getParameter("limit"));
     
      MemberVO vo=new MemberVO();
      vo.setPassword(password);
      vo.setId(id);
      vo.setName(name);
      vo.setLimit(limit);
      MemberVO totalVO = (MemberVO) session.getAttribute("mvo");
      
      vo.setTotal(totalVO.getTotal());
      
      //System.out.println("vo"+ vo.toString());
      session.setAttribute("mvo", vo);
      
      MemberDAO.getInstance().updateMember(vo);
      
      return "/member/modify_result.jsp";
   }
}