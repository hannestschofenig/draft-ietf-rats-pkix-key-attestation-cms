ContentInfo:
  contentType: id-signedData
  SignedData:
    version: v3
    digestAlgorithms: SHA-256 (parameters absent)
    encapContentInfo:
      eContentType: 1.3.6.1.5.5.999.3.0
      eContent: DER(TbsEvidence), 1027 octets
      TbsEvidence:
        version: 1
        Element[0]: transaction
          nonce: beefcafebabedead
          timestamp: 20261019170235Z
          ak-spki: DER SubjectPublicKeyInfo (91 octets)
          ak-spki: DER SubjectPublicKeyInfo (294 octets)
        Element[1]: platform
          hwmodel: 48534d2d39303030
        Element[2]: key
          identifier: 9a25f603-a2c4-4dad-9ee0-a1b4e771f2c3
          spki: DER SubjectPublicKeyInfo (91 octets)
          extractable: false
          never-extractable: true
          sensitive: true
          local: true
          purpose: 1.3.6.1.5.5.999.2.4
        Element[3]: key
          identifier: 85704b99-7097-4bca-93b6-13352f865ace
          spki: DER SubjectPublicKeyInfo (91 octets)
          extractable: true
          sensitive: false
    certificates: 2 X.509 signing certificate(s)
      serial: 1001
      subject CN: CMS Draft Example HSM
      KU: digitalSignature; EKU: 1.3.6.1.5.5.7.3.999
      serial: 1002
      subject CN: CMS Draft Example HSM
      KU: digitalSignature; EKU: 1.3.6.1.5.5.7.3.999
    signerInfos: 2 alternative signature(s)
      SignerInfo[0]:
        version: v1
        sid: issuerAndSerialNumber (serial 1001)
        issuer CN: CMS Draft Example Root
        digestAlgorithm: SHA-256 (parameters absent)
        signedAttrs:
          content-type: 1.3.6.1.5.5.999.3.0
          message-digest (hex):
            a5e56812f2aa4f6e2964747145f4734e
            6f31731497c6d47be40a00154fab5e42
          cmsAlgorithmProtect:
            digestAlgorithm: SHA-256 (parameters absent)
            signatureAlgorithm:
              ecdsa-with-SHA256 (parameters absent)
        signatureAlgorithm:
          ecdsa-with-SHA256 (parameters absent)
        signature: verified with included certificate
      SignerInfo[1]:
        version: v1
        sid: issuerAndSerialNumber (serial 1002)
        issuer CN: CMS Draft Example Root
        digestAlgorithm: SHA-256 (parameters absent)
        signedAttrs:
          content-type: 1.3.6.1.5.5.999.3.0
          message-digest (hex):
            a5e56812f2aa4f6e2964747145f4734e
            6f31731497c6d47be40a00154fab5e42
          cmsAlgorithmProtect:
            digestAlgorithm: SHA-256 (parameters absent)
            signatureAlgorithm:
              rsaEncryption (NULL parameters)
        signatureAlgorithm:
          rsaEncryption (NULL parameters)
        signature: verified with included certificate
    crls: absent
    unsignedAttrs: absent in all SignerInfo values
Encoded ContentInfo length: 2887 octets
