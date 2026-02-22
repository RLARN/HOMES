package com.eksystems.homes.scm.vo;

import java.time.LocalDateTime;

public class ScmVO {
	private Long depReqSeq;
	private String familyId;

	private String purItemSeq;
	private String storeInfo;

	private Long amount;
	private String reqDesc;   // ✅ REQ_DESC

	private String regId;
	private LocalDateTime regDt;

	private String updId;
	private LocalDateTime updDt;
	
	private String requestDt;
	private String reqStatus;

	public String getRequestDt() { return requestDt; }
	
	public void setRequestDt(String requestDt) {
		this.requestDt = requestDt; }
	
	public Long getDepReqSeq() {
		return depReqSeq;
	}
	public void setDepReqSeq(Long depReqSeq) {
		this.depReqSeq = depReqSeq;
	}
	public String getFamilyId() {
		return familyId;
	}
	public void setFamilyId(String familyId) {
		this.familyId = familyId;
	}
	public String getPurItemSeq() {
		return purItemSeq;
	}
	public void setPurItemSeq(String purItemSeq) {
		this.purItemSeq = purItemSeq;
	}
	public String getStoreInfo() {
		return storeInfo;
	}
	public void setStoreInfo(String storeInfo) {
		this.storeInfo = storeInfo;
	}
	public Long getAmount() {
		return amount;
	}
	public void setAmount(Long amount) {
		this.amount = amount;
	}
	public String getReqDesc() {
		return reqDesc;
	}
	public void setReqDesc(String reqDesc) {
		this.reqDesc = reqDesc;
	}
	public String getRegId() {
		return regId;
	}
	public void setRegId(String regId) {
		this.regId = regId;
	}
	public LocalDateTime getRegDt() {
		return regDt;
	}
	public void setRegDt(LocalDateTime regDt) {
		this.regDt = regDt;
	}
	public String getUpdId() {
		return updId;
	}
	public void setUpdId(String updId) {
		this.updId = updId;
	}
	public LocalDateTime getUpdDt() {
		return updDt;
	}
	public void setUpdDt(LocalDateTime updDt) {
		this.updDt = updDt;
	}

	public String getReqStatus() {
		return reqStatus;
	}

	public void setReqStatus(String reqStatus) {
		this.reqStatus = reqStatus;
	}






}
