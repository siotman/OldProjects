package org.kosta.goodmove.model.service;

import java.util.List;
import java.util.Map;

import org.kosta.goodmove.model.vo.ApplicationVO;
import org.kosta.goodmove.model.vo.DeliveryVO;
import org.kosta.goodmove.model.vo.MemberVO;

public interface DeliveryService {

	public DeliveryVO login(DeliveryVO dvo);

	void register(DeliveryVO dvo);

	int idcheck(String id);

	int getTotalDelivery();

	int passwordCheck(String password);

	void deleteDelivery(DeliveryVO dvo);

	public void convertDoneState(String id, String bno, String currState);

	List<ApplicationVO> getAllDeliveryList();

	Map<String, MemberVO> getDeliveryDetail(String id, String bno);

	List<DeliveryVO> getNotConfirmedDeliveryList();
	

}
