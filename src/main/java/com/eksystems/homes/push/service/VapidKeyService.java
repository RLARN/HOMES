package com.eksystems.homes.push.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.jce.spec.ECNamedCurveGenParameterSpec;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.File;
import java.math.BigInteger;
import java.security.*;
import java.security.interfaces.ECPrivateKey;
import java.security.interfaces.ECPublicKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;
import java.util.Map;

@Service
public class VapidKeyService {

    private static final Logger log = LoggerFactory.getLogger(VapidKeyService.class);

    @Value("${push.vapid.subject}")
    private String subject;

    @Value("${push.vapid.keys-file}")
    private String keysFilePath;

    private ECPublicKey  publicKey;
    private ECPrivateKey privateKey;
    private String       publicKeyBase64;   // uncompressed 65-byte, base64url

    @PostConstruct
    public void init() throws Exception {
        if (Security.getProvider(BouncyCastleProvider.PROVIDER_NAME) == null) {
            Security.addProvider(new BouncyCastleProvider());
        }

        File keyFile = new File(keysFilePath);
        if (keyFile.exists()) {
            loadFromFile(keyFile);
        } else {
            generateAndSave(keyFile);
        }

        log.info("[VAPID] Public Key (copy to browser test): {}", publicKeyBase64);
    }

    // ── Load ──────────────────────────────────────────────────────────────────

    private void loadFromFile(File keyFile) throws Exception {
        @SuppressWarnings("unchecked")
        Map<String, String> keys = new ObjectMapper().readValue(keyFile, Map.class);

        publicKeyBase64 = keys.get("publicKey");
        publicKey = decodePublicKey(publicKeyBase64);

        byte[] privBytes = Base64.getUrlDecoder().decode(padBase64(keys.get("privateKey")));
        privateKey = (ECPrivateKey) KeyFactory.getInstance("EC", "BC")
                .generatePrivate(new PKCS8EncodedKeySpec(privBytes));

        log.info("[VAPID] Loaded keys from {}", keyFile.getAbsolutePath());
    }

    // ── Generate ─────────────────────────────────────────────────────────────

    private void generateAndSave(File keyFile) throws Exception {
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("EC", "BC");
        kpg.initialize(new ECNamedCurveGenParameterSpec("prime256v1"));
        KeyPair kp = kpg.generateKeyPair();

        publicKey  = (ECPublicKey)  kp.getPublic();
        privateKey = (ECPrivateKey) kp.getPrivate();

        publicKeyBase64 = encodePublicKey(publicKey);
        String privateKeyBase64 = Base64.getUrlEncoder().withoutPadding()
                .encodeToString(privateKey.getEncoded());

        new ObjectMapper().writeValue(keyFile, Map.of(
                "publicKey",  publicKeyBase64,
                "privateKey", privateKeyBase64
        ));
        log.info("[VAPID] Generated new VAPID keys → {}", keyFile.getAbsolutePath());
    }

    // ── EC key helpers ────────────────────────────────────────────────────────

    /** EC public key → uncompressed 65-byte → base64url */
    public static String encodePublicKey(ECPublicKey key) {
        byte[] uncompressed = new byte[65];
        uncompressed[0] = 0x04;
        byte[] x = toUnsigned32(key.getW().getAffineX());
        byte[] y = toUnsigned32(key.getW().getAffineY());
        System.arraycopy(x, 0, uncompressed, 1,  32);
        System.arraycopy(y, 0, uncompressed, 33, 32);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(uncompressed);
    }

    /** base64url uncompressed-65-byte → ECPublicKey */
    public static ECPublicKey decodePublicKey(String base64url) throws Exception {
        byte[] bytes = Base64.getUrlDecoder().decode(padBase64(base64url));
        return decodePublicKeyFromBytes(bytes);
    }

    public static ECPublicKey decodePublicKeyFromBytes(byte[] bytes) throws Exception {
        // Parse uncompressed EC point using BouncyCastle, then wrap as JCE key
        org.bouncycastle.jce.spec.ECNamedCurveParameterSpec bcSpec =
                org.bouncycastle.jce.ECNamedCurveTable.getParameterSpec("prime256v1");
        org.bouncycastle.math.ec.ECPoint bcPoint = bcSpec.getCurve().decodePoint(bytes);

        org.bouncycastle.jce.spec.ECNamedCurveSpec ecSpec =
                new org.bouncycastle.jce.spec.ECNamedCurveSpec(
                        "prime256v1", bcSpec.getCurve(), bcSpec.getG(), bcSpec.getN(), bcSpec.getH());

        java.security.spec.ECPoint w = new java.security.spec.ECPoint(
                bcPoint.getAffineXCoord().toBigInteger(),
                bcPoint.getAffineYCoord().toBigInteger()
        );
        return (ECPublicKey) KeyFactory.getInstance("EC", "BC")
                .generatePublic(new java.security.spec.ECPublicKeySpec(w, ecSpec));
    }

    public static byte[] toUnsigned32(BigInteger value) {
        byte[] src = value.toByteArray();
        byte[] dst = new byte[32];
        if (src.length >= 32) {
            System.arraycopy(src, src.length - 32, dst, 0, 32);
        } else {
            System.arraycopy(src, 0, dst, 32 - src.length, src.length);
        }
        return dst;
    }

    public static String padBase64(String s) {
        int pad = (4 - s.length() % 4) % 4;
        return s + "=".repeat(pad);
    }

    // ── Accessors ─────────────────────────────────────────────────────────────

    public ECPublicKey  getPublicKey()       { return publicKey; }
    public ECPrivateKey getPrivateKey()      { return privateKey; }
    public String       getPublicKeyBase64() { return publicKeyBase64; }
    public String       getSubject()         { return subject; }
}
