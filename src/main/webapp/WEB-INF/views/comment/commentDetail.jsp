<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<script>
	function sendList(){
		location.href="getCommentList.do";
	}
	function updateComment(){
		if(confirm("수정하시겠습니까?")){
			location.href="commentUpdateView.do?cno="+${requestScope.cvo.cno};
		}else{
			return false;
		}
	}
	function deleteComment(){
		if(confirm("삭제하시겠습니까?")){
			location.href="";
		}else{
			return false;
		}
	}
	function fn_formSubmit() {
		var f = document.replyWriteForm;
		if($("#rememo").val()==""){
			alert("댓글을 입력해주세요!");
			return;
		}else{
			f.submit();
		}
	}
	function fn_replyDelete(rno,cno){
		if(confirm("삭제하시겠습니까?")){
			location.href ="deleteCommentReply.do?rno="+rno+"&cno="+cno;
		}else{
			return;
		}
	}
	//댓글 수정버튼 클릭시 수정창 나타나게 하기
	var updaterno = updateRememo = null;
	function fn_replyUpdate(rno){
	    var form = document.replyUpdateForm;
	    var reply = document.getElementById("reply"+rno);
	    var replyDiv = document.getElementById("replyDiv");
	    replyDiv.style.display = "";
	    if (updaterno) {
	        document.body.appendChild(replyDiv);
	        var oldrno = document.getElementById("reply"+updaterno);
	        oldrno.innerText = updateRememo;
	    } 
	    
	    form.rno.value=rno;
	    form.rememo.value = reply.innerText;
	    reply.innerText ="";
	    reply.appendChild(replyDiv);
	    updaterno   = rno;
	    updateRememo = form.rememo.value;
	    form.rememo.focus(); 
	} 

	// 댓글 수정버튼->저장 누를때 
	function fn_replyUpdateSave(){
	    var form = document.replyUpdateForm;
	    var rno = document.replyUpdateForm.rno;
	    var cno = document.replyUpdateForm.cno;
	    if (form.rememo.value=="") {
	        alert("글 내용을 입력해주세요.");
	        form.rememo.focus();
	        return;
	    }
		if(confirm("댓글을 수정하시겠습니까?")){
			form.action="updateCommentReply.do";
			form.submit();
		}
	    //form.action="updateCommentReply.do?rno="+rno+"&cno="+cno+"&rememo="+form.rememo.value;
	    //form.submit();     
	} 
	// 댓글 수정하고 취소 누르기
	function fn_replyUpdateCancel(){
	    var form = document.replyUpdateForm;
	    var replyDiv = document.getElementById("replyDiv");
	    document.body.appendChild(replyDiv);
	    replyDiv.style.display = "none";
	    
	    var oldrno = document.getElementById("reply"+updaterno);
	    oldrno.innerText = updateRememo;
	    updaterno = updateRememo = null; 
	} 
	
	
	
	// 대댓글
	function hideDiv(id){
	    var div = document.getElementById(id);
	    div.style.display = "none";
	    document.body.appendChild(div);
	}

	function fn_replyReply(rno){
	    var form = document.form3;
	    var reply = document.getElementById("reply"+rno);
	    var replyDia = document.getElementById("replyDialog");
	    replyDia.style.display = "";
	    
	    if (updaterno) {
	        fn_replyUpdateCancel();
	    } 
	    
	    form.rememo.value = "";
	    form.reparent.value=rno;
	    reply.appendChild(replyDia);

	} 
	function fn_replyReplyCancel(){
	    hideDiv("replyDialog");
	} 

	function fn_replyReplySave(){
	    var form = document.form3;
	    var param = form.reparent.value
	    if (form.rememo.value=="") {
	        alert("글 내용을 입력해주세요.");
	        form.rememo.focus();
	        return;
	    }
	    form.action="writeCommentReply.do";
	    form.submit();    
	}
</script>
<table id="inputForm" class="table table-hover">
	<tbody>
		<tr>
			<td>NO : ${requestScope.cvo.cno}</td>
			<td colspan="2">${requestScope.cvo.title}</td>
		</tr>
		<tr>
			<td>작성자 : ${requestScope.cvo.id}</td>
			<td>${requestScope.cvo.time_posted}</td>
			<td>조회수 : ${requestScope.cvo.hit}</td>
		</tr>
		<tr>
			<td colspan="3"><pre>${requestScope.cvo.content}</pre></td>
		</tr>
		<tr>
			<td valign="middle" align="center" colspan="3">
			 <input class="btn btn-info"  type="button" value="목록" onclick="sendList()" >
			 <input class="btn btn-info" type="button" value="수정" onclick="updateComment()">
			 <input class="btn btn-info" type="button" value="삭제" onclick="deleteComment()">
			 <br><br>			
			 </td>
		</tr>
	</tbody>
</table>
<!-- 댓글구간 -->
<div class="reply_container">
	<c:if test="${sessionScope.mvo != null}">
		<div class="replyList">
			<form name="replyWriteForm" action="writeCommentReply.do" method="post">
				<input type="hidden" name="parent" value="0">
				<input type="hidden" name="reFlag" value="false">
				<input type="hidden" name="cno" value="${requestScope.cvo.cno}">
				<textarea class="reply_field" id="rememo" name="rememo"
				placeholder="댓글을 달아주세요." style="border:solid 3px #ffd100;"></textarea>
				<input type="button" id="writeReplyBtn"  value="등록" onclick="fn_formSubmit()">
			</form>
		</div>
	</c:if>

	<!-- 댓글 리스트 -->
	<div class="box_reply">
		<ul class="cmlist">
			<c:forEach items="${requestScope.CommentReplyList}" var="reply">
				<li>
				<div class="h">
					<span class="nickspan"> <c:if test="${reply.depth >=1 }">&nbsp;&nbsp;&nbsp;&nbsp;
						<img class="reply_icon" src="${pageContext.request.contextPath}/img/reply_icon.png" width="20">
						</c:if>${reply.name}</span> <span class="cmdate">${reply.time_posted }</span>
						<span class="recmbtn">
						<a href="#"	onclick="fn_replyReply(${reply.rno})">
				 		<img class="reply_icon" src="${pageContext.request.contextPath}/img/bu_arr.png">답글 </a></span> 
						<span class="cmbtn">
						<c:if test="${sessionScope.mvo.id==reply.id}">
						<a onclick="fn_replyDelete(${reply.rno },${requestScope.cvo.cno})">삭제</a>
						<a onclick="fn_replyUpdate(${reply.rno })">수정</a>
						</c:if></span>
				</div>
				<div class="cm_list_box" id="reply<c:out value="${reply.rno}"/>">
					<c:out value="${reply.content }" />
				</div>
				</li>
			</c:forEach>
		</ul>
	</div>
	
	<!--  댓글 수정시 나오는 부분 -->
	<div id="replyDiv" style="width: 99%; display: none">
		<form name="replyUpdateForm" action="updateCommentReply.do" method="post">
			<input type="hidden" name="cno" value="${requestScope.cvo.cno}">
			 <input type="hidden" name="rno">
			<textarea class="reply_field" name="rememo" rows="3" cols="60"
			maxlength="500"></textarea>
			<a onclick="fn_replyUpdateSave()">저장</a>
			<a onclick="fn_replyUpdateCancel()">취소</a>
		</form>
	</div>
	
	<!--  대댓글 창 -->
	<div id="replyDialog" style="width: 99%; display: none">
		<form name="form3" action="board6ReplySave" method="post">
			<input type="hidden" name="reFlag" value="true">
			<input type="hidden" name="cno" value="<c:out value="${requestScope.cvo.cno}"/>"> 
			<input type="hidden" name="rno"> 
			<input type="hidden" name="reparent">
			<input type="hidden" name="parent" value="0">
			<textarea class="reply_field" name="rememo" rows="3" cols="60" maxlength="500" style="border:solid 3px #ffd100;
			background-color: #FAFAAA;margin-left:10px;"></textarea>
			<a onclick="fn_replyReplySave()">저장</a>
			<a onclick="fn_replyReplyCancel()">취소</a>
		</form>
	</div>
</div>