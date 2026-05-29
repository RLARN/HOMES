package com.eksystems.homes.push.vo;

public class PushSubscriptionVO {
    private Long   id;
    private String familyId;
    private String userId;
    private String userAuth;
    private String endpoint;
    private String p256dh;
    private String auth;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getFamilyId() { return familyId; }
    public void setFamilyId(String familyId) { this.familyId = familyId; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getUserAuth() { return userAuth; }
    public void setUserAuth(String userAuth) { this.userAuth = userAuth; }

    public String getEndpoint() { return endpoint; }
    public void setEndpoint(String endpoint) { this.endpoint = endpoint; }

    public String getP256dh() { return p256dh; }
    public void setP256dh(String p256dh) { this.p256dh = p256dh; }

    public String getAuth() { return auth; }
    public void setAuth(String auth) { this.auth = auth; }
}
