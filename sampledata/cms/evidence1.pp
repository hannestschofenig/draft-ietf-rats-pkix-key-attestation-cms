ContentInfo:
  contentType: id-signedData
  SignedData:
    version: v3
    digestAlgorithms: SHA-256 (parameters absent)
    encapContentInfo:
      eContentType: 1.3.6.1.5.5.999.3.0
      eContent: DER(TbsEvidence), 329 octets
      TbsEvidence:
        version: 1
        Element[0]: transaction
          nonce: deadbeefcafebabe
          timestamp: 20261019170235Z
          ak-spki: DER SubjectPublicKeyInfo (91 octets)
        Element[1]: platform
          vendor: Acme Corp
          hwmodel: 48534d2d39303030
          hwversion: 2.1.0
          fipsboot: true
          fipslevel: 3
          uptime: 86400
    certificates: 1 X.509 signing certificate(s)
      serial: 1001
      subject CN: CMS Draft Example HSM
      KU: digitalSignature; EKU: 1.3.6.1.5.5.7.3.999
    signerInfos: 1 alternative signature(s)
      SignerInfo[0]:
        version: v1
        sid: issuerAndSerialNumber (serial 1001)
        issuer CN: CMS Draft Example Root
        digestAlgorithm: SHA-256 (parameters absent)
        signedAttrs:
          content-type: 1.3.6.1.5.5.999.3.0
          message-digest (hex):
            19f3e65c6be3b51db39006a3c4e9cfe6
            a1c82ca98a06774963c92c255e5e90f7
          cmsAlgorithmProtect:
            digestAlgorithm: SHA-256 (parameters absent)
            signatureAlgorithm:
              ecdsa-with-SHA256 (parameters absent)
        signatureAlgorithm:
          ecdsa-with-SHA256 (parameters absent)
        signature: verified with included certificate
    crls: absent
    unsignedAttrs: absent in all SignerInfo values
Encoded ContentInfo length: 1096 octets
