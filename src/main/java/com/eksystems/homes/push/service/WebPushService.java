package com.eksystems.homes.push.service;

import com.eksystems.homes.push.mapper.PushMapper;
import com.eksystems.homes.push.vo.PushSubscriptionVO;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.jose4j.jws.AlgorithmIdentifiers;
import org.jose4j.jws.JsonWebSignature;
import org.jose4j.jwt.JwtClaims;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.KeyAgreement;
import javax.crypto.Mac;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.io.ByteArrayOutputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.KeyPairGenerator;
import java.security.SecureRandom;
import java.security.interfaces.ECPrivateKey;
import java.security.interfaces.ECPublicKey;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@Service
public class WebPushService {

    private static final Logger log = LoggerFactory.getLogger(WebPushService.class);

    private final VapidKeyService vapidKeyService;
    private final PushMapper      pushMapper;
    private final ObjectMapper    objectMapper = new ObjectMapper();
    private final HttpClient      httpClient   = HttpClient.newHttpClient();

    public WebPushService(VapidKeyService vapidKeyService, PushMapper pushMapper) {
        this.vapidKeyService = vapidKeyService;
        this.pushMapper      = pushMapper;
    }

    /** familyId 내 manager 전원에게 비동기 푸시 발송 */
    public void sendToManagers(String familyId, String title, String body, String url) {
        CompletableFuture.runAsync(() -> {
            try {
                List<PushSubscriptionVO> subs = pushMapper.selectManagerSubscriptions(familyId);
                if (subs == null || subs.isEmpty()) {
                    log.debug("[PUSH] No manager subscriptions for familyId={}", familyId);
                    return;
                }

                String payload = objectMapper.writeValueAsString(Map.of(
                        "title", title,
                        "body",  body,
                        "url",   url
                ));

                for (PushSubscriptionVO sub : subs) {
                    try {
                        sendOne(sub, payload);
                    } catch (Exception e) {
                        log.warn("[PUSH] Failed for sub userId={}: {}", sub.getEndpoint(), e.getMessage());
                    }
                }
            } catch (Exception e) {
                log.warn("[PUSH] sendToManagers error: {}", e.getMessage());
            }
        });
    }

    // ── Single push ───────────────────────────────────────────────────────────

    private void sendOne(PushSubscriptionVO sub, String payload) throws Exception {
        byte[] userPubBytes  = Base64.getUrlDecoder().decode(VapidKeyService.padBase64(sub.getP256dh()));
        byte[] userAuthBytes = Base64.getUrlDecoder().decode(VapidKeyService.padBase64(sub.getAuth()));

        // VAPID audience = scheme + host
        URI endpointUri = URI.create(sub.getEndpoint());
        String audience = endpointUri.getScheme() + "://" + endpointUri.getHost()
                + (endpointUri.getPort() != -1 ? ":" + endpointUri.getPort() : "");

        String vapidJwt = createVapidJwt(audience);
        byte[] encrypted = encryptPayload(payload.getBytes(StandardCharsets.UTF_8), userPubBytes, userAuthBytes);

        HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create(sub.getEndpoint()))
                .header("Content-Encoding", "aes128gcm")
                .header("Content-Type", "application/octet-stream")
                .header("TTL", "86400")
                .header("Authorization", "vapid t=" + vapidJwt + ",k=" + vapidKeyService.getPublicKeyBase64())
                .POST(HttpRequest.BodyPublishers.ofByteArray(encrypted))
                .build();

        HttpResponse<String> res = httpClient.send(req, HttpResponse.BodyHandlers.ofString());
        if (res.statusCode() >= 300) {
            log.warn("[PUSH] HTTP {} from push endpoint", res.statusCode());
        } else {
            log.debug("[PUSH] Sent OK, status={}", res.statusCode());
        }
    }

    // ── VAPID JWT (RFC 8292) ──────────────────────────────────────────────────

    private String createVapidJwt(String audience) throws Exception {
        JwtClaims claims = new JwtClaims();
        claims.setAudience(audience);
        claims.setSubject(vapidKeyService.getSubject());
        claims.setExpirationTimeMinutesInTheFuture(24 * 60);
        claims.setIssuedAtToNow();

        JsonWebSignature jws = new JsonWebSignature();
        jws.setAlgorithmHeaderValue(AlgorithmIdentifiers.ECDSA_USING_P256_CURVE_AND_SHA256);
        jws.setKey(vapidKeyService.getPrivateKey());
        jws.setPayload(claims.toJson());
        return jws.getCompactSerialization();
    }

    // ── Content Encryption (RFC 8291 / aes128gcm) ────────────────────────────

    private byte[] encryptPayload(byte[] plaintext, byte[] userPubBytes, byte[] userAuth) throws Exception {
        byte[] salt = new byte[16];
        new SecureRandom().nextBytes(salt);

        // Ephemeral server keypair
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("EC", "BC");
        kpg.initialize(new org.bouncycastle.jce.spec.ECNamedCurveGenParameterSpec("prime256v1"));
        java.security.KeyPair serverKp = kpg.generateKeyPair();
        ECPublicKey  serverPub  = (ECPublicKey)  serverKp.getPublic();
        ECPrivateKey serverPriv = (ECPrivateKey) serverKp.getPrivate();

        ECPublicKey userPublicKey = VapidKeyService.decodePublicKeyFromBytes(userPubBytes);

        // ECDH
        KeyAgreement ka = KeyAgreement.getInstance("ECDH", "BC");
        ka.init(serverPriv);
        ka.doPhase(userPublicKey, true);
        byte[] sharedSecret = ka.generateSecret();

        byte[] serverPubBytes = rawPublicKey(serverPub);

        // RFC 8291 key derivation
        // PRK_key = HKDF-Extract(salt=userAuth, IKM=sharedSecret)
        byte[] prkKey = hkdfExtract(userAuth, sharedSecret);

        // auth_info = "WebPush: info\0" || userPubBytes || serverPubBytes
        byte[] authInfo = concat(
                "WebPush: info\0".getBytes(StandardCharsets.UTF_8),
                userPubBytes,
                serverPubBytes
        );
        // IKM' = HKDF-Expand(PRK_key, auth_info, 32)
        byte[] ikm = hkdfExpand(prkKey, authInfo, 32);

        // PRK = HKDF-Extract(salt=salt_random, IKM=IKM')
        byte[] prk = hkdfExtract(salt, ikm);

        byte[] cek   = hkdfExpand(prk, "Content-Encoding: aes128gcm\0".getBytes(StandardCharsets.UTF_8), 16);
        byte[] nonce = hkdfExpand(prk, "Content-Encoding: nonce\0".getBytes(StandardCharsets.UTF_8), 12);

        // Pad: plaintext + 0x02 (end-of-record delimiter)
        byte[] padded = Arrays.copyOf(plaintext, plaintext.length + 1);
        padded[plaintext.length] = 0x02;

        // AES-128-GCM
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE,
                new SecretKeySpec(cek, "AES"),
                new GCMParameterSpec(128, nonce));
        byte[] ciphertext = cipher.doFinal(padded);

        // aes128gcm header: salt(16) + rs(4,BE=4096) + idlen(1=65) + serverPub(65) + ciphertext
        ByteBuffer buf = ByteBuffer.allocate(16 + 4 + 1 + 65 + ciphertext.length);
        buf.put(salt);
        buf.putInt(4096);
        buf.put((byte) 65);
        buf.put(serverPubBytes);
        buf.put(ciphertext);
        return buf.array();
    }

    // ── HKDF (RFC 5869, SHA-256) ──────────────────────────────────────────────

    private byte[] hkdfExtract(byte[] salt, byte[] ikm) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(salt, "HmacSHA256"));
        return mac.doFinal(ikm);
    }

    private byte[] hkdfExpand(byte[] prk, byte[] info, int length) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(prk, "HmacSHA256"));
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] t = new byte[0];
        for (int i = 1; out.size() < length; i++) {
            mac.reset();
            mac.update(t);
            mac.update(info);
            mac.update((byte) i);
            t = mac.doFinal();
            out.write(t);
        }
        return Arrays.copyOf(out.toByteArray(), length);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private byte[] rawPublicKey(ECPublicKey key) {
        byte[] x = VapidKeyService.toUnsigned32(key.getW().getAffineX());
        byte[] y = VapidKeyService.toUnsigned32(key.getW().getAffineY());
        byte[] out = new byte[65];
        out[0] = 0x04;
        System.arraycopy(x, 0, out, 1,  32);
        System.arraycopy(y, 0, out, 33, 32);
        return out;
    }

    private byte[] concat(byte[]... parts) {
        int len = 0;
        for (byte[] p : parts) len += p.length;
        byte[] result = new byte[len];
        int off = 0;
        for (byte[] p : parts) { System.arraycopy(p, 0, result, off, p.length); off += p.length; }
        return result;
    }
}
