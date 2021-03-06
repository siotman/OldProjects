<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<link rel="stylesheet" type="text/css"
   href="${pageContext.request.contextPath }/resources/member/result.css">
<script type="text/javascript">
function pageOut(){
   location.href="${pageContext.request.contextPath}/home.do";
}
function keypress(){
   if(event.keyCode==13){
      location.href = "${pageContext.request.contextPath}/home.do";
   }
}
</script>
</head>
<body onkeypress="keypress()">
   <!-- 배너 타이틀 -->
<section id="page-breadcrumb">
   <div class="vertical-center sun">
      <div class="container">
         <div class="row">
            <div class="action">
               <div class="col-sm-4">
                  <h1 class="title">회원정보수정 결과</h1>
                  <p>
                     <br>회원 정보가 수정되었어요
                  </p>
               </div>
            </div>
         </div>
      </div>
   </div>
</section>
<!--배너 타이틀-->
<div class = "">
	<div class ="container">
		<div class = "row">
			<div align="center">
				<h1>
					 ${param.id}님<br> 
					 회원정보가 수정되었습니다.
				</h1>
			<input type="button" value="확인" id = "resBtn" onclick="pageOut()">
			</div>
		</div>
	</div>
</div>
</body>
</html>