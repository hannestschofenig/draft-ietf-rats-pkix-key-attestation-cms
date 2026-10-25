---
title: CMS Evidence Encoding for Hardware Security Modules
abbrev: CMS Evidence for HSMs
docname: draft-ietf-rats-pkix-key-attestation-cms-latest

category: std
consensus: true
submissiontype: IETF

ipr: trust200902
area: "Security"
workgroup: "RATS"
keyword:
  - Internet-Draft
  - RATS
  - PKIX
  - HSM
coding: utf-8

stand_alone: yes
pi:
  rfcedstyle: yes
  toc: yes
  tocindent: yes
  sortrefs: yes
  symrefs: yes
  strict: yes
  comments: yes
  inline: yes
  text-list-symbols: -o*+
  docmapping: yes
  toc_levels: 4
venue:
  group: RATS
  type: Working Group
  mail: rats@ietf.org
  arch: https://datatracker.ietf.org/wg/rats/about/
  github: "ietf-rats-wg/key-attestation"

author:
  - name: Jean-Pierre Fiset
    org: Crypto4A Inc.
    abbrev: Crypto4A
    street: 1550A Laperriere Ave
    city: Ottawa, Ontario
    country: Canada
    code: K1Z 7T2
    email: jp@crypto4a.com

  - name: Mike Ounsworth
    org: Cryptic Forest Software
    abbrev: Cryptic Forest
    city: Sioux Lookout
    country: Canada
    email: mike@ounsworth.ca

  - name: Hannes Tschofenig
    org: University of the Bundeswehr Munich
    abbrev: UniBw M.
    city: Neubiberg
    region: Bavaria
    country: Germany
    code: 85579
    email: hannes.tschofenig@gmx.net

  - name: Henk Birkholz
    org: Fraunhofer SIT
    email: henk.birkholz@ietf.contact

  - name: Monty Wiseman
    country: United States of America
    email: monty.wiseman@oracle.com
  -
    ins: N. Smith
    name: Ned Smith
    org:
    country: United States
    email: ned.smith.ietf@gmail.com

normative:
  RFC9334:
  RFC5280:
  RFC9711:
  RFC4648:
  RFC5652:
  RFC5911:
  RFC6211:
  RFC5035:
  RFC5752:
  RFC7468:
  X680:
    title: "Information technology — ASN.1: Specification of basic notation"
    author:
      - org: ITU-T
    target: https://www.itu.int/rec/T-REC-X.680
  X690:
    title: "Information technology — ASN.1 encoding rules: BER, CER, DER"
    author:
      - org: ITU-T
    target: https://www.itu.int/rec/T-REC-X.690
  PKCS11:
    title: "PKCS #11 Specification Version 3.1"
    author:
      - name: Dieter Bong
      - name: Tony Cox
      - org: OASIS PKCS 11 TC
    date: 2022-08-11
    target: https://docs.oasis-open.org/pkcs11/pkcs11-spec/v3.1/cs01/pkcs11-spec-v3.1-cs01.html
  FIPS140-3:
    title: "Security Requirements for Cryptographic Modules"
    author:
      - org: NIST, Information Technology Laboratory
    seriesinfo:
      FIPS: 140-3
    target: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.140-3.pdf

informative:
  RFC6024:
  RFC9019:
  I-D.ietf-lamps-csr-attestation:
  I-D.ounsworth-rats-privacy-framework:
  CNSA2.0:
    title: "Commercial National Security Algorithm Suite 2.0"
    author:
      - org: National Security Agency
    target: https://media.defense.gov/2022/Sep/07/2003071834/-1/-1/0/CSA_CNSA_2.0_ALGORITHMS_.PDF
  CSBR:
    title: "Baseline Requirements for the Issuance and Management of Publicly-Trusted Code Signing Certificates Version 3.8.0"
    author:
      - org: CA/Browser Forum
    target: https://cabforum.org/working-groups/code-signing/documents/

entity:
  SELF: "RFCthis"

--- abstract

This document specifies a vendor-agnostic format for Evidence produced and verified within a PKIX context.
The Evidence produced this way includes claims collected about a cryptographic module, such as a Hardware Security
Module (HSM),
and elements found within it such as cryptographic keys.

One scenario envisaged is that the state information about the cryptographic module can be securely presented
to a remote operator or auditor in a vendor-agnostic verifiable format.
A more complex scenario would be to submit this Evidence to a Certification Authority to aid in determining
whether the storage properties of this key meet the requirements of a given certificate profile.

The claims are encoded in ASN.1/DER and protected using a restricted CMS
SignedData profile with one or more Attestation Key signatures.

--- middle

# Introduction

This document specifies a vendor-neutral Evidence format for remote attestation in PKIX-based environments, with a focus on hardware security modules (HSMs)
and cryptographic keys managed by such devices. The format enables an Attester to convey measured platform and key properties to a Verifier and, ultimately,
to a Relying Party in a form that integrates with existing X.509-based trust infrastructures.

Concretely, this specification defines:

* a profile of CMS SignedData {{RFC5652}} carrying a DER-encoded Evidence
  description, one or more SignerInfo values, and signing certificates;

* an element-and-claim data model organized around transaction, platform, and key elements, identified by OIDs;

* encoding and signature-verification processing rules for PKIX Evidence.

The design is intentionally PKIX-native. ASN.1 and DER are used to align with existing certificate tooling, certification authority workflows, and HSM implementations where non-ASN.1 formats are less common.

This document does not define a transport protocol for carrying Evidence, does not define Verifier appraisal policy, and
does not standardize device-internal authentication/authorization mechanisms. It defines the data model and cryptographic container
so that such mechanisms can be applied consistently across deployments.

## Status of this comparison version {#sec-cms-comparison-status}

This is an editorial alternative to the draft-specific envelope in
`draft-ietf-rats-pkix-key-attestation.md`, based on the design note
`profiled_cms.md`. It is provided for comparison and does not represent an
adopted replacement or an additional interoperable encoding of that envelope.
The use cases, information model, element and claim definitions, and Presenter
role are retained. {{sec-cms-changes}} records the substantive changes.

This version specifies the certificate-based baseline, including mandatory
algorithm protection and optional signing-certificate binding. It also defines
an optional RFC 5752 variant for deployments needing stronger binding between
parallel signatures. The base profile accepts at least one acceptable signature
from the Attester; it does not require all signatures to verify.

Every signing certificate is carried in the Evidence. SPKI-only and arbitrary
key-ID-only operation, allowed by the draft-specific envelope, are not defined
by this version. CMS can support uncertified public-key references, but the
resolution, identity, and trust rules for those modes remain an extension
design task; see {{sec-cms-key-modes}}.


# Use Cases

This section covers use cases that motivated the development of this specification.


## Continuous Assurance

There are situations where it is necessary to verify the current running state of an HSM as part of operational or
auditing procedures. For example, there are devices that are certified to work in an environment only if certain
versions of the firmware are loaded or only if user keys are protected with specific policies.

The Evidence format offered by this specification allows a platform to report its firmware level along with
other collected claims necessary in critical deployments.


## Key import and HSM clustering

Consider that an HSM is being added to a logical HSM cluster. Part of the onboarding process involves
the newly-added HSM providing Evidence of its running state, for example that it is a genuine device from
the same manufacturer as the existing clustered HSMs, firmware patch level, FIPS mode, etc.
It could also be required to provide information about any system-level keys required to establish
secure cluster communication. In this scenario, the Verifier and Relying Party will typically be other HSMs in the cluster
deciding whether or not to admit the new HSM.

A related scenario is when performing a key migration across HSMs.
If the key is being migrated is associated with certain properties, for example an environment running in FIPS mode at
FIPS Level 3, and the key is set to certain protection properties such as Non-Exportable and Dual-Control,
then the HSM might wish to verify that the key was previously stored under the same conditions.
This specification provides an Evidence format with sufficient details to support this type of
implementation across HSM vendors.

These scenarios motivate the design requirements to have an ASN.1 based Evidence format and a data model that
more closely matches typical HSM architecture since, as shown in both scenarios,
an HSM is acting as Verifier and Relying Party.


## Attesting subject of a certificate issuance

Prior to a Certification Authority (CA) issuing a certificate on behalf of a subject, a number of procedures
are required to verify that the subject of the certificate is associated with the key that is certified.
In some cases, such as issuing a code signing certificate {{CNSA2.0}} {{CSBR}}, a CA must ensure that
the subject key is located in a Hardware Security Module (HSM).

The Evidence format offered by this specification is designed to carry the information necessary for a CA to
assess the location of the subject key along a number of commonly-required attributes. More specifically, a CA could
determine which HSM was used to generate the subject key, whether this device adheres
to certain jurisdiction policies (such as FIPS mode) and the constraints applied to the key (such as whether is it extractable).
The use of Evidence in a certification request is specified in {{I-D.ietf-lamps-csr-attestation}}.

For relatively simple HSM devices, storage properties such as "extractable" may always be false for all keys
since the devices are not capable of key export and so the Evidence could be essentially a hard-coded template asserting these
immutable attributes. However, more complex HSM devices require a more elaborate Evidence format that encompasses the
mutability of these attributes.

Also, a client requesting a key attestation might wish to scope-down the content of the produced Evidence as
the HSM contains much more information than that which is relevant to the transaction.
Not reducing the scope of the generated Evidence could, in some scenarios, constitute a privacy violation.


# Conventions and Terminology {#terminology}

{::boilerplate bcp14-tagged}

This specification uses a necessary mixture of PKI terminology and RATS Architecture definitions
in order to map concepts between the two domains.

The reader is assumed to be familiar with the vocabulary and concepts
defined in the RATS Architecture ({{RFC9334}}) such as Attester,
Relying Party, Verifier.

The reader is assumed to be familiar with common vocabulary and concepts
defined in {{RFC5280}} such as certificate, signature, attribute, verification and validation.

In order to avoid confusion, this document generally
capitalizes RATS terms such as Attester, Relying Party, and Claim.
Therefore, for example, a "Verifier"
should be assumed to be an entity that checks the validity of Evidence as per {{RFC9334}},
whereas a "verifier" could be a more general reference to a PKI entity that checks
the validity of an X.509 certificate or other digital signature as per {{RFC5280}}.

The following terms are used in this document:

{: vspace="0"}

Attestation Key (AK):
: Cryptographic key controlled solely by the Attester and used only for the purpose
of producing Evidence. In other words, it is used to digitally sign the claims collected by
the Attester.

Attester:
: The term Attester respects the definition offered in {{RFC9334}}. In this specification, it
is also interchangeable with "platform" or "HSM".

Attesting Environment:
: As defined in {{RFC9334}}, the Attesting Environment collects the information to be represented
in Claims. In practical terms, an implementation may be designed with services to perform this function.
To remain consistent with the RATS Architecture, the term "Attesting Environment" is used throughout
this specification.

Evidence:
: The term Evidence respects the definition offered in {{RFC9334}}. In this specification, it
refers to claims, encoded according to the format defined within this document, and signed using
Attestation Keys.

Hardware Security Module (HSM):
: A physical computing device that safeguards and manages secrets, such as cryptographic keys,
and performs cryptographic operations based on those secrets.
This specification takes a broad definition of what counts as an HSM to include smartcards,
USB tokens, TPMs, cryptographic co-processors (PCI cards) and "enterprise-grade" or "cloud-service grade" HSMs
(possibly rack mounted). In this specification, it is interchangeable with "platform" or "Attester".

Key Attestation:
: Process of producing Evidence containing claims pertaining to user keys found within an HSM. In
general, the claims include enough information about a user key and its hosting platform to allow
a Relying Party to make judicious decisions about the key, such as whether to issue a certificate for the key.

RATS:
: Remote ATtestation procedureS. Refers to a working group within IETF and all the documents developed
under this umbrella of efforts. This specification is developed using concepts developed in RATS but more
particularly refers to the RATS Architecture as introduced in {{RFC9334}}.

PKIX:
: Public Key Infrastructure based on X.509 certificates. Refers to the framework of technology, policies and
procedures used to manage and distribute digital certificates based on {{RFC5280}} and related specifications.

Platform:
: The module or device that embodies the Attester. In this specification, it is interchangeable with
"Attester" or "HSM".

Platform Attestation:
: Process of producing evidence containing claims pertaining to measured values associated with the platform itself. In general, the claims include
enough information about the platform to allow a Relying Party to make judicious decisions about the
platform, such as those carried out during audit reviews.

Presenter:
: Role that facilitates communication between the Attester and the Verifier. The
Presenter initiates the operation of generating Evidence at the Attester and
passes the generated Evidence to the Verifier. The interface by which the Presenter
initiates Evidence generation is outside the scope of this specification.

Trust Anchor:
: As defined in {{RFC6024}} and {{RFC9019}}, a Trust Anchor
"represents an authoritative element via a public key and
associated data. The public key is used to verify digital
signatures, and the associated data is used to constrain the types
of information for which the trust anchor is authoritative." The
Trust Anchor may be a certificate, a raw public key, or other
structure, as appropriate.

Trusted Platform Module (TPM):
: A tamper-resistant processor generally located on a computer's motherboard used to enhance attestation
functions for the hosting platform as defined by the Trusted Computer Group. TPMs are very specialized Hardware Security Modules and generally use
other protocols (than the one presented in this specification) to transmit Evidence.

User Key:
: A user key consists of a key hosted by an HSM (the platform) and intended to be used by a client
of the HSM. Other terms used for a user key are "application key", "client key" or "operational key".
The access and operations on a user key are controlled by the HSM.

## Claims and measurements in generated Evidence

The RATS Architecture {{RFC9334}} states that Evidence is made up of claims and that a claim is "a piece of
asserted information, often in the form of a name/value pair". The RATS Architecture also mentions
the concept of "measurements" that "can describe a variety of attributes of system components, such
as hardware, firmware, BIOS, software, etc., and how they are hardened."

Some HSMs have a large amount of memory and can therefore contain a substantial amount of elements that
can be observed independently by the Attesting Environment. Each of those elements, in turn, can contain a
number of measurable attributes.

A certain level of complexity arises as multiple elements of the same class690 can be reported simultaneously in generated
Evidence. In this case, multiple similar claims are reported simultaneously but associated with different elements.

For example, two independent user keys could be reported simultaneously in Evidence. Each key is associated with a
SPKI (SubjectPublicKeyInfo). The measured values for the SPKI of the respective keys are different.

To that end, in this specification, the claims are organized as collections where each claim is the association of
a claim type with the measured value. The collections, in turn, are organized by "elements". An element represents a
logical portion of the Target Environment that is observed by the Attesting Environment.

Thus, an element is associated with a collection of claims. Each claim is the association of a claim type
with a measured value.

The grouping of claims into elements facilitates the comprehension of a large addressable space into
portions recognizable by the user. More importantly, it curtails the produced Evidence to portions of the
Target Environment that relate to the needs of the Verifier. See {{sec-cons-privacy}}.


## Attestation Key Certificate Chain {#sec-ak-chain}

The data format in this specification represents Evidence and
requires third-party endorsement in order to establish trust. Part of this
endorsement is a trust anchor that chains to the HSM's attestation key (AK)
which signs the Evidence. In practice the trust anchor usually is a
manufacturing CA belonging to the device vendor which proves
that the device is genuine and not counterfeit. The trust anchor can also belong
to the device operator as would be the case when the AK certificate is replaced
as part of onboarding the device into a new operational environment.

The AK certificate associated with the AK that signs the evidence have the following constraints:

* the certificate MUST include the Extended Key Usage (EKU) certificate extension;

* the EKU certificate extension MUST include the `id-kp-attestationKey`, as defined in this specification; and,

* the `KeyUsage` extension (KU) MUST have the `digitalSignature` bit set.

An EKU that includes only a single KeyPurposeId of `id-kp-attestationKey` SHOULD be marked as `critical`.
The reasoning here is that the usage of a true attestation key is constrained by the security module it's
contained by.  Presenting non-attestation data for validation by this AK public key should ALWAYS fail.

An EKU that includes a KeyPurposeId of `id-kp-attestationKey` along with other attestation-related
KeyPurposeId SHOULD NOT be marked as critical.

The CMS profile specified in {{sec-data-model}} requires one or more
`SignerInfo` values. Multiple values allow one Attester identity, represented
by a single subject DN within a defined trusted naming context, to use distinct
Attestation Keys and signature algorithms. Signing certificates are included in
`SignedData.certificates`; a certificate's inclusion is not itself a trust
decision. See {{sec-cms-identity}} and {{sec-verif-proc}} for the processing rules.

## Presenter Role {#presenter}

This specification introduces the role of "Presenter" as shown in {{fig-presenter}}. The Presenter is the role that initiates the generation of
Evidence. Since HSMs are generally servers (client/server relationship) or peripherals (controller/peripheral relationship), a Presenter is
required to launch the process of creating the Evidence and capturing it to forward it to the Verifier.

~~~
+-----------------------------+
|  Attester (HSM)             |
|                             |
|      +------------------+   |
|      | Target           |   |
|      | Environment      |   |
|      | (Elements &      |   |
|      |  values)         |   |
|      +-------+----------+   |
|              |              |
|              | Collect      |
|              | Claims(3)    |
|              v              |
|      +------------------+   |
|      | Attesting        |   |
|      | Environment      |   |
|      +--------+---------+   |
|            ^  |             |
|            |  |             |
+------------+--+-------------+
             |  |
 Attestation |  |   Evidence(4)
 Request(2)  |  |
             |  v
     +----------------+   Nonce(1)  +------------+
     |                |<------------|            |
     |    Presenter   |             |  Verifier  |
     |                |------------>|            |
     +----------------+ Evidence(5) +------------+
~~~
{: #fig-presenter title="Presenter Role"}


The process of generating Evidence generally starts at the Verifier with the generation of a nonce. The nonce is used to ensure freshness
of the Evidence and this quality is guaranteed by the Verifier. Therefore, if a nonce is used, it must be provided to the Presenter by
the Verifier (1).

An Attestation Request (request) is assembled by the Presenter and submitted to the HSM (2). The Attesting Environment parses the request and
collects the appropriate measurements from the Target Environment (3).

In the previous figure, the HSM is represented as being composed of an Attesting Environment and a Target Environment. This representation is offered
as a simplified view and implementations are not required to adhere to this separation of concerns.

The Attesting Environment produces Evidence based on the collected information and returns it to the Presenter for distribution (4). Finally, the
Presenter forwards the Evidence to the Verifier (5).

The aim of the figure is to depict the position of the Presenter as an intermediate role between the Attester and the Verifier.
The role of "Presenter" is privileged as it controls the claims included in the Evidence being generated by the Attester. However, the role is not "trusted" as
the Verifier does not have to take into account the participation of the Presenter as part of the function of appraising the Evidence.

The attestation request is a message used by the presenter to specify the elements and the associated claims that are included by the Attester in the
generated Evidence. The nonce specified by the Verifier MUST be included in the attestation request for the Attester to include in the Evidence.

The nature and format of the attestation request is not dictated by this specification.

# Information Model {#sec-info-model}

The Evidence format is composed of two main sections:

* An Evidence description which describes the list of reported elements.

* A signature section where one or more digital signatures are offered to prove the origin of the
  Evidence description and maintain its integrity.

The details of the signature section is left to the data model. The remainder of this section
deals with the way the information is organized to form the Evidence description.

The Evidence description is associated with elements to help with the organization and comprehension
of the information. Elements are portions of the Target Environment observed by the Attesting
Environment. Each element, in turn, is associated with a collection of claims that describes the attributes
of the element.

Therefore, the Evidence description is composed of a set of elements and each element is composed
of a claim set.

## Element

An element is a logical construct that refers to a portion of the Target Environment's state. It is
addressable via an identifier such as a UUID or a handle (as expressed in {{PKCS11}}). In general, an
element refers to a component recognized by users of the HSM, such as a user key or the platform itself.

An element is composed of a type, the element type, and a collection of claims. The element type
describes the class of the element while the collection of claims defines its state.

An element MUST be reported at most once in an Evidence description. The Evidence description can
have multiple elements of the same type (for example reporting multiple keys), but each
element MUST relate to different portions of the Target Environment.

It is possible for two elements to be quite similar such as in a situation where a key is imported
twice in a HSM. In this case, the two related elements could be associated with similar claims. However, they
are treated as different elements as they are reporting different portions of the Target Environment.

The number of elements reported in an Evidence description, and their respective type, is
left to the implementer. For a simple device where there is only one key, the list of
reported elements could be fixed. For larger and more complex devices, the list of
reported elements should be tailored to the intended use and authorized recipient of the Evidence.

In particular, note that the `nonce` claim contained with the Transaction element is optional,
and therefore it is possible that an extremely simple device that holds one static key
could have its Evidence generated at manufacturing time and injected
statically into the device instead of
being generated on-demand. This model would essentially
off-board the Attesting Environment to be part of the manufacturing infrastructure. In the RATS
Architecture, this configuration would refer to the the information provided this way as an Endorsement
provided by the manufacturer as opposed to Evidence generated by the HSM.


## Element Type

An element is defined by its type. This specification defines three element types:

* Platform : This element holds claims that describes the state of the platform (or device)
  itself. Elements of this type hold claims that are global
  in nature within the Target Environment.

* Key : The elements of this type represent a cryptographic key protected within the
  Target Environment and hold claims that describes that specific key.

* Transaction : This element is abstract in nature since it is associated with claims
  that do not describe portions of the Target Environment. Instead, these claims
  relate to the Evidence-generation transaction, such as a `nonce` to support freshness.

Although this document defines a short list of element types, this list is extensible
to allow implementers to report on elements found in their implementation and not
covered by this specification. By using an Object Identifiers (OID) for specifying element types
and claim types, this format is inherently extensible;
implementers of this specification MAY define new custom or proprietary element types and
place them alongside the standardized elements, or define new claim types
and place them inside standardized elements.

Verifiers SHOULD ignore and skip over
unrecognized element or claim types and continue processing normally.
In other words, if a given Evidence would have been acceptable without the
unrecognized elements or claims, then it SHOULD still be acceptable with them.


## Claim Type

Each claim found in an element is composed of a claim type and a value.
Each claim describes a portion of the state from the associated element. For example,
a platform element could have a claim which indicates the firmware version currently running.
Another example is a key element with a claim that reports whether the key is extractable
or not.690

A value provided by a claim is to be interpreted within the context
of its element and in relation to the claim type.

A claim type MUST be defined for a specific element type to reduce
confusion when it comes to interpretation of the value. In other words, a specific claim type MUST
NOT be used by multiple element types. For example, if a concept of "revision" is applicable to a platform
and a key, the claim for one element type (platform revision) should have a different identifier
from the one for the other element type (key revision).

The nature of the value (boolean, integer, string, bytes) and its format are dependent on the claim type.

This specification defines a limited set of claim types. However, the list is extensible
through the IANA registration process or private OID allocation, enabling implementers to
report additional claims not covered by this specification.

The number of claims reported within an element, and their respective type, is
left to the implementer. For a simple device, the reported list of claims for an element
might be fixed. However, for larger and more complex devices, the list of reported claims
should be tailored to the intended use and authorized recipient of the Evidence.

Claims of a particular type MAY be repeated within an element while others MUST NOT. For example, for a
platform element, there can only be one "firmware version" claim. Therefore, the associated claim
MUST NOT be repeated as it may lead to confusion. Other claim definitions can allow
multiple independent values. Therefore, the definition of a claim specifies whether or not multiple copies of that
claim are allowed within an element's claim set.

If a Verifier detects, within a single element, multiple copies of a claim type that should not
be repeated, it MUST reject the Evidence as malformed. Since a Verifier is encouraged to ignore
unrecognized claim types, it is possible that a potential rejection is missed.

If a Verifier encounters, within the context of an element, a repeated claim for a type where
it is allowed, it MUST treat each one as an independent claim and MUST NOT
consider later ones to overwrite the previous one.

# Data Model {#sec-data-model}

This section describes the data model associated with generated Evidence. For ease of
deployment within the target ecosystem, ASN.1 definitions {{X680}} and DER encoding
{{X690}} are used. A complete ASN.1 module is provided in {{sec-asn1-mod}}.

## Evidence Content {#sec-cms-content}

`Evidence` is a CMS `ContentInfo` whose `contentType` is `id-signedData`.
Its content is a `SignedData` value as specified in {{RFC5652}}. CMS ASN.1
types are imported from {{RFC5911}}; they are not redefined by this document.

The following application-specific types and content-type registration describe
the Evidence description carried within CMS:

~~~ asn.1
Evidence ::= ContentInfo

TbsEvidence ::= SEQUENCE {
    version INTEGER,
    reportedElements SEQUENCE SIZE (1..MAX) OF ReportedElement
}

id-evidence-contentType OBJECT IDENTIFIER ::= { id-evidence 3 }
id-ct-keyAttestationEvidence OBJECT IDENTIFIER ::=
    { id-evidence-contentType 0 }

ct-keyAttestationEvidence CONTENT-TYPE ::= {
    TbsEvidence IDENTIFIED BY id-ct-keyAttestationEvidence
}
~~~

The alias `Evidence` does not by itself express the CMS profile constraints.
Implementations MUST additionally enforce {{sec-cms-profile}}. In particular,
`Evidence` is not an arbitrary CMS object.

`TbsEvidence` corresponds to the "Evidence Description" in {{sec-info-model}}.
For compliance with this specification, `TbsEvidence.version` MUST be `1`.
This version identifies the application content syntax, independently of the
CMS version fields. A compatibility-breaking change to that syntax requires a
new content version; a change to the envelope profile must define its own
compatibility and profile-identification rules.

## CMS Profile {#sec-cms-profile}

### Encapsulation and Versions

The complete outer `ContentInfo` MUST be DER encoded. Its `contentType` MUST
be `id-signedData`, and `SignedData.version` MUST be `v3`. The latter follows
from the use of a non-`id-data` encapsulated content type and the restricted
certificate choices in this profile.

`SignedData.encapContentInfo.eContentType` MUST be
`id-ct-keyAttestationEvidence`. `eContent` MUST be present and contain exactly
one DER-encoded `TbsEvidence` value, with no trailing data. Detached content,
other outer CMS content types, and CMS nesting inside `eContent` MUST NOT be
generated or accepted by this profile.

The resulting structure is:

~~~
ContentInfo (id-signedData)
  SignedData (version v3)
    digestAlgorithms
    encapContentInfo
      eContentType = id-ct-keyAttestationEvidence
      eContent = DER(TbsEvidence)
    certificates
    signerInfos (one or more SignerInfo values)
~~~

### Certificates and Signer Identification {#sec-cms-certificates}

Generators MUST use `issuerAndSerialNumber` for `SignerInfo.sid`. Verifiers
MUST also support the `subjectKeyIdentifier` form required by {{RFC5652}};
in this profile it references the signing certificate's SubjectKeyIdentifier
extension. `SignerInfo.version` MUST be `v1` for `issuerAndSerialNumber` and
`v3` for `subjectKeyIdentifier`.

Each referenced end-entity signing certificate MUST be included in
`SignedData.certificates`. Only the X.509 `certificate` alternative of
`CertificateChoices` is permitted; other alternatives MUST be rejected.
Certificates MUST satisfy the AK constraints in {{sec-ak-chain}} before their
signatures can be accepted. Intermediate CA certificates MAY be included to
assist certification-path construction. Trust anchors SHOULD NOT be included;
including a certificate never establishes it as a trust anchor. Certificate
order has no application significance, although DER set ordering applies.

`SignedData.crls` MUST be absent. Verifiers obtain revocation information as
required by their validation policy. Certification-path construction and
validation follow {{RFC5280}} and the configured appraisal policy.

### Signed Attributes {#sec-cms-attributes}

Each `SignerInfo.signedAttrs` MUST contain exactly one instance of each of the
following attributes, with exactly one value in each instance:

* `content-type`, with value `id-ct-keyAttestationEvidence`;
* `message-digest`, with the digest of the `eContent` value octets, calculated
  using that `SignerInfo`'s digest algorithm; and
* `cmsAlgorithmProtect`, as defined in {{RFC6211}}, containing the digest and
  signature algorithm identifiers and their parameters from that `SignerInfo`.
  Its signature-algorithm field MUST be present and its MAC field MUST be absent.

The first two attributes are required by CMS for non-`id-data` content.
Requiring `cmsAlgorithmProtect` is an additional rule of this profile. A
Verifier MUST check the protected identifiers against the corresponding outer
fields using the comparison rules of {{RFC6211}}. A mismatch prevents
acceptance of that signature.

A generator MAY include one `SigningCertificateV2` attribute with one value
as specified by {{RFC5035}}. Verifiers MUST process it when present, including
checking the signing-certificate hash. A deployment requiring authenticated
binding to the exact signing certificate MUST require the attribute in both
generation and verification. A certificate reference in `sid` does not itself
authenticate that certificate selection, and an `ak-spki` claim binds a key
rather than a particular certificate containing it.

No other signed attributes are permitted in the base profile. The optional
variant in {{sec-cms-signature-set}} additionally permits
`multiple-signatures`. Generators and Verifiers MUST enforce the selected
attribute set. `SignerInfo.unsignedAttrs` MUST be absent; in particular,
counter-signatures are prohibited.

Signatures cover the DER `SET OF` encoding of the signed attributes according
to Section 5.4 of {{RFC5652}}, not the context-specific `[0]` tag used for
`signedAttrs` within `SignerInfo`. The encapsulated content is protected
through the authenticated `message-digest` attribute. Implementations MUST
use the CMS processing rules for the selected signature algorithm.

`SignedData.digestAlgorithms` MUST list each digest algorithm used by a
`SignerInfo` exactly once and MUST NOT contain unused algorithms.

### One Attester with Multiple Attestation Keys {#sec-cms-identity}

`SignedData.signerInfos` MUST contain at least one `SignerInfo`. Multiple
entries are used only for alternative signatures by one Attester identity.
The signing certificates MUST have equal subject DNs under the name-comparison
rules of {{RFC5280}}, and MUST contain pairwise-distinct SPKIs. All entries
protect the same encapsulated `TbsEvidence` value.

Deployments MUST define the trusted naming context in which those DNs identify
one Attester, or an explicit policy mapping across PKIs. Subject-DN uniqueness
in {{RFC5280}} is scoped to entities certified by one CA. Equal DNs alone MUST
NOT establish identity equivalence across independent manufacturer PKIs.

A Verifier MUST successfully validate at least one signature and certification
path acceptable under its appraisal policy. It MAY validate additional
signatures it supports. An unsupported or unacceptable algorithm does not
invalidate another acceptable signature for the same Attester. This is an
alternative-signature model; cryptographic verification of every signature is
not a condition of base-profile acceptance.

### Signature-Set Binding {#sec-cms-signature-set}

Removing one `SignerInfo` does not invalidate the remaining signatures. Under
the base acceptance model, each Verifier MUST enforce its own algorithm policy
without assuming that every signature originally generated remains present.

The signed `transaction.ak-spki` claims identify the selected signing keys.
A deployment MAY require a matching `SignerInfo` for every listed AK, as a
reverse completeness check in addition to the signer-to-claim check in
{{sec-verif-proc}}. After the content is authenticated, this detects a missing
block for a distinct AK. It does not bind the block's algorithms or attributes,
or establish that its signature is valid. The base profile does not require
this reverse check.

Deployments needing authenticated references between the parallel signature
information MAY select the {{RFC5752}} variant. The choice MUST be fixed by
application or deployment policy before acceptance, rather than inferred from
untrusted claims about the desired policy. For multiple signatures by the
Attester, generators MUST include `multiple-signatures` in every `SignerInfo`;
Verifiers MUST enforce that requirement and the generation and processing
rules of {{RFC5752}}. A singleton with that attribute still requires checking
its references for missing entries. The other permitted attributes and their
processing remain unchanged. Application policy MUST specify whether a
detected missing reference causes Evidence rejection.

The variant binds digest and signature algorithm identifiers and the signed
attributes of the referenced entries, with certificate disambiguation where
required by {{RFC5752}}. It requires coordinated preparation of the attributes
before signing and a quadratic number of cross-reference values. It does not
by itself change the acceptance rule to require every signature to verify.

### Other Key-Identification Modes {#sec-cms-key-modes}

This version requires an included X.509 certificate for every signer's key.
It does not define SPKI-only operation, arbitrary key-ID-only operation, or
external certificate resolution. These are deliberate limits of this profile,
not inherent limits of CMS.

A future profile could use `subjectKeyIdentifier` for trusted external keys
and use signed `ak-spki` claims for in-band SPKI carriage. It would need to
define identifier matching, failed resolution, common Attester identity across
keys, and the source of trust in the absence of certificates. A public key
included in Evidence cannot establish its own trustworthiness.

## Elements and Claims {#sec-elements-claims}

As described in {{sec-info-model}}, the `TbsEvidence` is a collection of elements. Each element
is associated with a type that defines its class. The element types are represented by object identifiers
(OIDs). The following ASN.1 fragment defines the structures associated with elements:

~~~ asn.1
ReportedElement ::= SEQUENCE {
    elementType         OBJECT IDENTIFIER,
    claims             SEQUENCE SIZE (1..MAX) OF ReportedClaim
}

id-evidence-element             OBJECT IDENTIFIER ::=
    { id-evidence 0 }
id-evidence-element-transaction OBJECT IDENTIFIER ::=
    { id-evidence-element 0 }
id-evidence-element-platform    OBJECT IDENTIFIER ::=
    { id-evidence-element 1 }
id-evidence-element-key         OBJECT IDENTIFIER ::=
    { id-evidence-element 2 }
~~~

In turn, elements are composed of a collection of claims. Each claim is composed of a type and a value.
The claim types are represented by object identifiers (OIDs). The
following ASN.1 fragment defines the structures associated with claims:

~~~ asn.1
CLAIM ::= CLASS {
    &id       OBJECT IDENTIFIER UNIQUE,
    &Type
} WITH SYNTAX {
    ID &id
    WITH TYPE &Type
}

ReportedClaim ::= SEQUENCE {
    claimType  CLAIM.&id ({ClaimSet}),
    value      CLAIM.&Type ({ClaimSet}{@claimType})
}

ClaimSet CLAIM ::= {
    -- claim definitions from this specification,
    ...
}
~~~

The `ClaimSet` object set in the complete ASN.1 module is extensible. This allows future or proprietary claim types to be encoded without changing the `ReportedClaim` syntax. A Verifier that does not recognize a claim type SHOULD ignore that claim as described in {{sec-info-model}}, unless local policy requires rejection. Every reported claim contains a value.

Each claim type SHOULD be associated with a single element type. Therefore, it is encouraged
to define claim types grouped with their respective element type.

The nature of a claim value is dictated by the claim type. When a claim type is defined, the
definition must include the type of the value, its semantic and interpretation.

The following ASN.1 fragment illustrates how a claim is associated with a type, in this case the
OID `id-evidence-claim-transaction-nonce` and the expected data format (OCTET STRING).

~~~ asn.1
id-evidence-claim-transaction-nonce     OBJECT IDENTIFIER ::=
    { id-evidence-claim-transaction 0 }

claim-transaction-nonce CLAIM ::= {
  ID id-evidence-claim-transaction-nonce
  WITH TYPE OCTET STRING
}
~~~

The remainder of this section describes the element types and their associated claims.


## Platform Element

A platform element reports information about the device where the Evidence is generated and is
composed of a collection of claims that are global to the Target Environment.
It is associated with the type identifier `id-evidence-element-platform`.

A platform element, if provided, MUST be included only once within the generated Evidence. If a
Verifier encounters multiple elements of type `id-evidence-element-platform`, it MUST
reject the Evidence as malformed.

The following table lists the claims for a platform element (platform claims) defined
within this specification. In cases where the claim is borrowed from another specification,
the "Reference" column refers to the specification where the semantics
for the claim value can be found.

| Claim Type      | Reference     | Multiple? | OID                                   |
| ---             | ---           | ---       | ---                                   |
| vendor          | {{&SELF}}     | No        | id-evidence-claim-platform-vendor     |
| oemid           | {{RFC9711}}   | No        | id-evidence-claim-platform-oemid      |
| hwmodel         | {{RFC9711}}   | No        | id-evidence-claim-platform-hwmodel    |
| hwversion       | {{RFC9711}}   | No        | id-evidence-claim-platform-hwversion  |
| hwserial        | {{&SELF}}     | No        | id-evidence-claim-platform-hwserial   |
| swname          | {{RFC9711}}   | No        | id-evidence-claim-platform-swname     |
| swversion       | {{RFC9711}}   | No        | id-evidence-claim-platform-swversion  |
| dbgstat         | {{RFC9711}}   | No        | id-evidence-claim-platform-debugstat  |
| uptime          | {{RFC9711}}   | No        | id-evidence-claim-platform-uptime     |
| bootcount       | {{RFC9711}}   | No        | id-evidence-claim-platform-bootcount  |
| fipsboot        | {{FIPS140-3}} | No        | id-evidence-claim-platform-fipsboot   |
| fipsver         | {{FIPS140-3}} | No        | id-evidence-claim-platform-fipsver    |
| fipslevel       | {{FIPS140-3}} | No        | id-evidence-claim-platform-fipslevel  |
| fipsmodule      | {{FIPS140-3}} | No        | id-evidence-claim-platform-fipsmodule |

Each claim defined in the table above is described in the following sub-sections.

### vendor

A human-readable string that reports the name of the device's manufacturer. This field is for informational
purposes only and should not be used in any automated mechanism to compare the Evidence. For the purposes of comparison,
the claims `oemid` and  `hwmodel` should be used.

If the device is submitted to FIPS validation, this string should correspond to the vendor field of the submission.

### oemid, hwmodel, hwversion, swname, swversion, dbgstat, uptime, bootcount

These claims are defined in {{RFC9711}} and are reused in this specification for interoperability. Small
descriptions are offered for each to ease the reading of this specification. In case of confusion between the
description offered here and the one in {{RFC9711}}, the definition offered in the latter shall prevail.

The claim "oemid" uniquely identifies the Original Equipment Manufacturer (OEM) of the HSM. This is a
sequence of bytes and is not meant to be a human readable string.

The claim "hwmodel" differentiates models, products, and variants manufactured by a particular OEM. A model
must be unique within a given "oemid". This is a sequence of bytes and is not meant to be a human readable string.

The claim "hwversion" is a text string reporting the version of the hardware. This claim must be
interpreted along with the claim "hwmodel".

The claim "swname" is a text string reporting the name of the firmware running on the platform.

The claim "swversion" differentiates between the various revisions of a firmware offered for the platform. This
is a string that is expected to be human readable.

The claim "dbgstat" refers to the state of the debug facilities offered by the HSM. This is an integer
value describing the current state as described in {{RFC9711}}.

The claim "uptime" reports the number of seconds that have elapsed since the HSM was last booted.

The claim "bootcount" reports the number of times the HSM was booted.

### hwserial

A human-readable string that reports the serial number of the hardware module. This serial number often matches the number engraved
on the case or on an applied sticker.

### fipsboot, fipsver, fipslevel and fipsmodule

FIPS 140-3 CMVP validation places stringent requirements on the mode of operation of the device and the cryptography offered by the module,
including only enabling FIPS-approved algorithms, certain requirements on entropy sources, and extensive start-up self-tests.
FIPS 140-3 offers compliance levels 1 through 4 with increasingly strict requirements. Many HSMs include a configuration setting that allows
the device to be taken out of FIPS mode and thus enable additional functionality or performance, and some offer configuration settings to change between compliance levels.

The boolean claim `fipsboot` indicates whether the device is currently operating in FIPS mode. When the claim value is "true", the HSM is running in compliance with the
FIPS 140 restrictions. If the value of this claim is "false", then the HSM is not
restricted to the behavior limited by compliance.

The textual claim `fipsver` indicates the version of the FIPS CMVP specification with which the device's operational mode is compliant. At the time of writing, the strings "FIPS 140-2" or "FIPS 140-3" SHOULD be used.

The integer claim `fipslevel` indicates the compliance level to which the device is currently operating and MUST only be 1, 2, 3, or 4. The `fipslevel` claim has no meaning if `fipsboot` is absent or `false`.

The claim `fipsmodule` is a textual field used to represent the name of the module that was submitted to CMVP for validation. The information derived by combining this claim with the vendor name shall
be sufficient to find the associated records in the CMVP database.

The FIPS status information found in Evidence indicates only the mode of operation of the device and is not authoritative of its validation status.
This information is available on the NIST CMVP website or by contacting the device vendor.
As an example, some devices may have the option to enable FIPS mode in configuration even if the vendor has not submitted this model for validation. As another example,
a device may be running in a mode consistent with FIPS Level 3 but the device was only validated and certified to Level 2.
A Relying Party wishing to know the validation status of the device MUST couple the device state information contained in the Evidence with a valid FIPS CMVP certificate for the device.


## Key Element

A key element is associated with the type `id-evidence-element-key`. Each instance of a
key element represents a different addressable key found in the Target Environment. There can
be multiple key elements found in Evidence, but each reported key element MUST
describe a different key observed from the Target Environment. Two key elements may represent the same underlying cryptographic key
(keys with the exact same value) but they must be different portions of the Target Environment.

A key element is composed of a collection of claims relating to the cryptographic key. At
minimum, a key element MUST report the claim "identifier" to uniquely identify this cryptographic
key from any others found in the same Target Environment.

A Verifier that detects Evidence with multiple key elements referring to the
same addressable key MUST reject the Evidence.

The following table lists the claims for a key element defined
within this specification. The "Reference" column refers to the specification where the semantics
for the claim can be found.

| Claim Type        | Reference   | Multiple? | OID                                     |
| ---               | ---         | ---       | ---                                     |
| identifier        | {{&SELF}}   | Yes       | id-evidence-claim-key-identifier        |
| spki              | {{&SELF}}   | No        | id-evidence-claim-key-spki              |
| extractable       | {{PKCS11}}    | No        | id-evidence-claim-key-extractable       |
| sensitive         | {{PKCS11}}    | No        | id-evidence-claim-key-sensitive         |
| never-extractable | {{PKCS11}}    | No        | id-evidence-claim-key-never-extractable |
| local             | {{PKCS11}}    | No        | id-evidence-claim-key-local             |
| expiry            | {{&SELF}}   | No        | id-evidence-claim-key-expiry            |
| purpose           | {{&SELF}}   | No        | id-evidence-claim-key-purpose           |

An attestation key might be visible to a client of the device and be reported along with other cryptographic keys. Therefore,
it is acceptable to include a key element providing claims about an attestation key like any other cryptographic key. An
implementation MAY reject the generation of Evidence if it relates to an attestation key.

### identifier

A human-readable string that uniquely identifies the cryptographic key. This value often contains
a UUID but could also have a numeric value expressed as text or any other textual description.

This claim MAY be repeated as some environments have more than one way to refer to a
cryptographic key.

### spki

The value of this claim contains the DER-encoded field SubjectPublicKeyInfo (see {{RFC5280}}) associated with the cryptographic
key.

### extractable, sensitive, never-extractable, local

These claims are defined as key attributes in {{PKCS11}} and reused in this specification for interoperability. Small
descriptions are offered for each to ease the reading of this specification. In case of confusion between the
description offered here and the one in {{PKCS11}}, the definition offered in the latter shall prevail.

The claim "extractable" indicates that the key can be exported from the HSM. Corresponds directly to the attribute CKA_EXTRACTABLE
found in PKCS#11.

The claim "sensitive" indicates that the value of key cannot leave the HSM in plaintext. Corresponds directly to the attribute CKA_SENSITIVE
found in PKCS#11.

The claim "never-extractable" indicates if the key was never extractable from the HSM throughout the life of the key. Corresponds
directly to the attribute CKA_NEVER_EXTRACTABLE found in PKCS#11.

The claim "local" indicates whether the key was generated locally or imported. Corresponds directly to the attribute CKA_LOCAL
found in PKCS#11.

### expiry

Reports a time after which the key is not to be used. The device MAY enforce this policy based on its internal clock.

Note that security considerations should be taken relating to HSMs and their internal clocks. See {{sec-cons-hsm-timestamps}}.

### purpose

Reports the key purposes, also referred to as key capabilities, associated with the subject key. Since multiple purposes can be associated with a single key,
the value of this claim is a list of purposes, each reported as an object identifier (OID).

The value of this claim is the DER encoding of the following structure:

~~~ asn.1

claim-key-purpose CLAIM ::= {
  ID id-evidence-claim-key-purpose
  WITH TYPE KeyPurposes
}

KeyPurposes ::= SEQUENCE OF OBJECT IDENTIFIER

~~~

The following table describes the key purposes defined in this specification. The key purposes offered are based on key
attributes provided by PKCS#11. Each purpose is assigned an object identifier (OID).

| Capability       | PKCS#11            | OID                                       |
| ---              | ---                | ---                                       |
| encrypt          | CKA_ENCRYPT        | id-evidence-key-capability-encrypt        |
| decrypt          | CKA_DECRYPT        | id-evidence-key-capability-decrypt        |
| wrap             | CKA_WRAP           | id-evidence-key-capability-wrap           |
| unwrap           | CKA_UNWRAP         | id-evidence-key-capability-unwrap         |
| sign             | CKA_SIGN           | id-evidence-key-capability-sign           |
| sign-recover     | CKA_SIGN_RECOVER   | id-evidence-key-capability-sign-recover   |
| verify           | CKA_VERIFY         | id-evidence-key-capability-verify         |
| verify-recover   | CKA_VERIFY_RECOVER | id-evidence-key-capability-verify-recover |
| derive           | CKA_DERIVE         | id-evidence-key-capability-derive         |
| decapsulate      | CKA_DECAPSULATE    | id-evidence-key-capability-decapsulate    |
| encapsulate      | CKA_ENCAPSULATE    | id-evidence-key-capability-encapsulate    |

The use of an object identifier to report a purpose allows third parties to extend this list to support
implementations that have other key purposes.

## Transaction Element

A transaction element is associated with the type `id-evidence-element-transaction`. This is
an abstract element and does not relate to any state found in the Target Environment. Instead, it
groups together claims that relate to the generation of the Evidence.

For example, a Verifier can supply a `nonce` for the generation of Evidence. This
`nonce` is included in the Evidence to support
the freshness of the Evidence. The `nonce` is not related to any portion of the Target Environment
and the transaction element is used to gather those values into claims.

A transaction element, if provided, MUST be included only once within the reported elements. If a
Verifier detects multiple elements of type `id-evidence-element-transaction`, it MUST
reject the Evidence.

The following table lists the claims for a transaction element defined
within this specification. The "Reference" column refers to the specification where the semantics
for the claim value can be found.


| Claim Type      | Reference     | Multiple? | OID                                      |
| ---             | ---           | ---       | ---                                      |
| nonce           | {{RFC9711}}   | No        | id-evidence-claim-transaction-nonce      |
| timestamp       | {{RFC9711}}   | No        | id-evidence-claim-transaction-timestamp  |
| ak-spki         | {{&SELF}}     | Yes       | id-evidence-claim-transaction-ak-spki    |

### nonce

The claim `nonce` is used to provide "freshness" quality as to the generated Evidence. If a nonce is used, it MUST be generated by the Verifier and
conveyed to the Attester, possibly through a Presenter. The Attester MUST include the nonce unchanged in the generated Evidence. The mechanism by which
the nonce is conveyed to the Attester is outside the scope of this specification.

This claim is similar to the "eat_nonce" as defined in {{RFC9711}}. According to that specification, this claim may be specified multiple times with
different values. However, within the scope of this specification, the "nonce" value can be specified only once within a transaction.

### timestamp

The time at which the Evidence was generated, according to the internal system clock of the Attesting Environment. This is similar to the
"iat" claim in {{RFC9711}}.

Note that security considerations should be taken relating to the evaluation of timestamps generated by HSMs. See {{sec-cons-hsm-timestamps}}.

### ak-spki

This claim contains the encoded Subject Public Key Information (SPKI) for the attestation key used to sign the Evidence. The definition
and encoding for SPKIs are defined in X.509 certificates ({{RFC5280}}).

This transaction claim is used to bind the content of the Evidence with the key(s) used to sign that Evidence. The importance
of this binding is discussed in {{sec-verif-proc}}.

This claim can be reported multiple times. Each included claim MUST refer to a different attestation key. In other words, this claim
should be repeated only if multiple attestation keys are used to sign the Evidence.

## Additional Element and Claim Types {#sec-additional-claim-types}

It is expected that HSM vendors will register additional Element and Claim types by assigning OIDs from their own proprietary OID arcs to hold data describing additional proprietary key properties.

When new element and claim types are used, documentation similar to the one produced in this specification SHOULD be distributed to
explain the semantics of the claims and the frequency that values can be provided.

See {{sec-req-verification}} and {{sec-cons-verifier}} for handling of unrecognized custom types.

## Encoding

The complete CMS `ContentInfo` and the `TbsEvidence` carried in `eContent`
MUST be DER encoded {{X690}}, as required by {{sec-cms-profile}}. The octets
hashed as content are the DER encoding of `TbsEvidence`, excluding the
surrounding CMS OCTET STRING tag and length.

If a textual representation is required, the DER encoding MAY be encoded into
Standard Base64 as defined in {{RFC4648}}. A textual encapsulation MUST use the
`CMS` label and the rules of {{RFC7468}}:

~~~
-----BEGIN CMS-----
(...)
-----END CMS-----
~~~

The `EVIDENCE` label identifies the draft-specific envelope and MUST NOT be
used for this CMS representation. Changing a label or wrapping an already
signed draft-specific Evidence object does not convert its signatures into
CMS signatures.

# Processing

This section deals with the exchanges between the Presenter, the Attester and the Verifier during the request, generation and consumption
of Evidence as defined in this specification. The architecture as shown in {{fig-presenter}} should be used as a reference for this section.

## Initiation from Presenter

The Presenter assembles a request to initiate the generation of Evidence by the Attester. This request selects the elements and the claims that
are to be included in the generated Evidence.

Ultimately, the generated Evidence is consumed by the Verifier. Therefore, a certain level of coordination is required between the Presenter and
the Verifier so that the generated Evidence includes the necessary information for the specific purpose.

The nonce used during the generation of Evidence is used to determine the freshness of the included information. Since the freshness is guaranteed
by the Verifier, the nonce is generally selected by the Verifier. If the Verifier generates the nonce, then it must be transmitted to the Presenter
prior to making the request. It is possible to devise schemes where a Presenter and a Verifier would agree to use a central "bell" as nonce,
alleviating the need to transmit the nonce between the two parties prior to the generation of the Evidence.

Finally, in the case where an Attester have multiple attestation keys, the Presenter need to select the attestation key(s) that are required by the
Verifier.

## Generation of Evidence

Upon receiving a request, the Attesting Environment verifies the validity of the request. This specification RECOMMENDS that:

* An Attesting Environment fails a request if it contains an unrecognized element. This is to ensure that all the semantics expected
by the Presenter are fully understood by the Attesting Environment.

* An Attesting Environment ignores unrecognized claim types for a specific element. In this situation, the Attesting Environment
is expected not to include the claim as part of the response. This guidance is intended to increase the likelihood of interoperability between
tools of different vendors.

* An Attesting Environment includes only elements and claims in the generated Evidence if these elements and claims were
specified as part of the request. This is to give control to the Presenter as to what information is disclosed by the Attesting Environment.

* An Attesting Environment fails a request if the Presenter does not have the appropriate access rights to the elements or claims included
in the request.

The Attesting Environment collects the necessary information from the Target Environment and assembles the `TbsEvidence` structure.

During the assembly of `TbsEvidence`, the Attesting Environment MUST:

* include the nonce (if present) provided by the Presenter to transaction element using the claim `claim-transaction-nonce`; and,

* add a claim of type `claim-transaction-ak-spki` to the transaction element to represent each attestation key selected to sign the
Evidence.

The Attesting Environment MUST use the following generation procedure:

1. Complete `TbsEvidence`, including all selected AK claims, and DER encode it
   exactly once. Those octets are shared by all `SignerInfo` values.
2. Place the octets in `encapContentInfo.eContent` and set `eContentType` to
   `id-ct-keyAttestationEvidence`.
3. For each selected AK, calculate the content digest and construct the signed
   attributes required by {{sec-cms-attributes}}. Include
   `SigningCertificateV2` when selected or required by deployment policy.
4. If the RFC 5752 variant is selected, prepare all mutual references using
   its specified generation procedure before calculating any signatures.
5. Generate each signature over the DER-encoded signed-attribute set using
   that AK's CMS signature processing rules, and construct its `SignerInfo`.
   Set `sid` to the signing certificate's issuer and serial number and set
   `SignerInfo.version` to `v1`.
6. Construct `SignedData` with version `v3`, the required digest-algorithm set,
   all `SignerInfo` values, and all signing certificates. Intermediate CA
   certificates MAY also be included. Omit CRLs and unsigned attributes.
7. Place `SignedData` in a `ContentInfo` with `contentType` set to
   `id-signedData`, and DER encode that outer value.

The Attesting Environment MUST enforce the binding between its observations,
the content digest, the signed attributes, and AK use. An interface that allows
an untrusted caller to supply arbitrary digests for AK signing does not meet
the generation requirements of this specification.

## Verification by Presenter {#sec-req-verification}

This sub-section describes the considerations that are relevant when a Presenter receives Evidence from the Attester (the HSM)
prior to distribution.

A Presenter is expected to review the Evidence produced by an Attester for fitness prior to distribution.

A Presenter is expected not to disclose Evidence if it contains information it
cannot parse. This restriction applies to element types and claim types. This is
to ensure that the information provided by the Attester can be evaluated by the
Presenter.

A Presenter is expected not to disclose Evidence if it contains elements other than the ones that were requested of the Attester. This is to ensure that only the
selected elements are exposed to the Verifier.

A Presenter is expected not to disclose Evidence if it contains an element with a claim
that was not requested of the Attester. This is to ensure that only the selected
information is disclosed to the Verifier.

Further privacy concerns are discussed in {{sec-cons-privacy}}.


## Verification Procedures {#sec-verif-proc}

The Verifier MUST validate the received `ContentInfo` against the profile in
{{sec-cms-profile}}, including DER encoding, the outer and encapsulated content
types, encapsulated-content presence, permitted certificate choices, version
fields, and at least one `SignerInfo`. Trailing data and malformed structures
MUST be rejected. No Evidence is accepted until both its cryptographic
protection and application content have passed the applicable checks.

The Verifier resolves every `SignerInfo.sid` to its included signing
certificate. A missing or ambiguous signing certificate MUST cause rejection
of the Evidence. It applies the same-Attester and distinct-SPKI rules of
{{sec-cms-identity}} within the configured trusted naming context. A generic
certificate parser SHOULD preserve syntactically valid SPKIs for algorithms
it cannot use, so that an unsupported alternative algorithm alone does not
prevent the other signatures from being evaluated.

For each signature considered for acceptance, the Verifier MUST:

1. Check the required and permitted signed attributes and their value counts.
   Check the authenticated content type and calculate the content digest over
   the received `eContent` value octets; compare it with `message-digest`.
2. Compare the `cmsAlgorithmProtect` value with that `SignerInfo`'s algorithm
   identifiers and parameters according to {{RFC6211}}. Process
   `SigningCertificateV2` according to {{RFC5035}} when present, and require it
   when the deployment requires exact certificate binding.
3. Verify the signature over the DER-encoded signed-attribute set using the
   referenced certificate's subject public key and the selected algorithm's
   CMS rules.
4. Check the signing certificate's KU `digitalSignature` bit and
   `id-kp-attestationKey` EKU as required by {{sec-ak-chain}}. Validate a
   certification path to a configured trust anchor, subject to the appraisal
   policy and required revocation checks. Included certificates are path
   construction material, not additional trust anchors.

Each `SignerInfo` is evaluated independently. The Verifier MUST successfully
validate at least one signature using an acceptable algorithm and certification
path. It MAY evaluate additional signatures. An unsupported or unacceptable
algorithm, or a failed signature-specific check above, prevents acceptance
through that `SignerInfo`; it does not by itself invalidate another acceptable
signature. Profile-wide structural, identity, or certificate-resolution
violations still cause rejection of the Evidence.

The Verifier MUST parse the authenticated content as exactly one DER-encoded
`TbsEvidence`, require version `1`, and enforce the element and claim rules of
{{sec-data-model}}. In particular, successful CMS verification does not waive
the restrictions on element counts, mandatory claims, claim types, or repeated
claims. Nonce, timestamp, and other appraisal checks are applied according to
the transaction context and Verifier policy.

If any `transaction.ak-spki` claims are present, the Verifier SHOULD check that
the SPKI of every referenced signing certificate matches at least one such
claim. A deployment requiring this check MUST enforce it in its appraisal
policy. A claim MUST NOT by itself be treated as proof that its key signed the
Evidence; that requires a successfully verified signature using the
corresponding AK and an acceptable certification path.

The Verifier MUST also enforce any selected completeness policy or RFC 5752
variant as specified in {{sec-cms-signature-set}}. Matching a listed AK to a
present block, establishing that all referenced signature information remains
present, and successfully verifying every signature are separate results.
Only successfully verified acceptable AKs may be reported as proven signers.

# ASN.1 Module {#sec-asn1-mod}

~~~ asn.1

<CODE STARTS>

{::include-fold Pkix-Key-Attest-CMS-2025.asn}

<CODE ENDS>

~~~

# IANA Considerations

Please replace "{{&SELF}}" with the RFC number assigned to this document.

For the ASN.1 module found in {{sec-asn1-mod}}, IANA is requested to assign
an object identifier for the module identifier (TBDMOD1) with a
description of "id-mod-pkix-evidence-cms-2025". This should be allocated in the
"SMI Security for PKIX Module Identifier" registry (1.3.6.1.5.5.7.0).

For the ASN.1 module found in {{sec-asn1-mod}}, IANA is requested to assign an
object identifier for the extended key usage `id-kp-attestationKey` (TBDMOD2).
This identifier should be allocated under the PKIX KP arc (1.3.6.1.5.5.7.3)
with the description "Extended Key Usage (EKU) for signing Evidence".

IANA is asked to define a new arc under "SMI Security for Mechanism Codes" (1.3.6.1.5.5) with the following
details:

* OID Value: 1.3.6.1.5.5.TBDMOD3

* Name: evidence

* Description: Evidence Encoding for Hardware Security Modules

* Reference: {{&SELF}}

Under this Evidence arc, this specification defines `id-evidence-contentType`
as `{ id-evidence 3 }` and `id-ct-keyAttestationEvidence` as
`{ id-evidence-contentType 0 }`, identifying the DER-encoded `TbsEvidence`
carried as CMS encapsulated content. The existing element, claim, and key
capability subarcs retain their assignments. No new CMS signed-attribute OIDs
are requested; this profile reuses the attributes in {{RFC5652}}, {{RFC6211}},
{{RFC5035}}, and, for the optional variant, {{RFC5752}}.

Editorial note: the module identifier and content-type allocation are proposed
for this alternative. All TBD identifiers require allocation before publication;
the temporary numeric values used in {{sec-cms-samples}} are not allocations.

# Security Considerations

## Policies relating to Verifier and Relying Party {#sec-cons-verifier}

The generation of Evidence by an HSM is to provide sufficient information to
a Verifier and, ultimately, a Relying Party to appraise the Target Environment (the HSM) and make
decisions based on this appraisal.

The Appraisal Policy associated with the Verifier influences the generation of the Attestation
Results. Those results, in turn, are consumed by the Relying Party to make decisions about
the HSM, which might be based on a set of rules and policies. Therefore, the interpretation of
the provided Evidence may greatly influence the outcome of some decisions.

A Verifier MAY reject Evidence if it lacks the claims required per the Verifier's
appraisal policy. For example, if a Relying Party mandates a FIPS-certified device,
it SHOULD reject Evidence lacking sufficient information to verify the device's FIPS
certification status.

If a Verifier encounters a claim with an unrecognized claim type, it MAY ignore it and
treat it as extraneous information. By ignoring a claim, the Verifier may accept Evidence
that would be deemed malformed to a Verifier with different policies. However, this approach
fosters a higher likelihood of achieving interoperability.

## Cryptographic Context and Signer Binding {#sec-cons-cms-binding}

The signed `content-type` attribute binds the content digest to this Evidence
type within CMS. It MUST be checked along with `eContentType`; accepting
arbitrary CMS SignedData under an Attestation Key would bypass that context
check. The AK remains restricted to Evidence generation as defined in this
document.

`cmsAlgorithmProtect` authenticates the algorithms and their parameters.
`transaction.ak-spki` binds the content to the claimed AKs, while
`SigningCertificateV2`, when required, binds a specific signing certificate.
These mechanisms address different substitution risks. Certificate inclusion
and equal subject DNs alone do not establish a trusted Attester identity.

Alternative signatures support different Verifier capabilities; they do not
automatically provide an all-signatures-required hybrid security property.
Policies must specify the acceptable algorithms and any completeness checks
without depending on the mere presence of a stronger-looking signature.

## Simple to Implement {#sec-cons-simple}

The nature of attestation requires the Attesting Environment to be implemented in an extremely
privileged position within the HSM so that it can collect the required measurements such as
hardware registers and the user keys. For many HSM architectures, this will
place the Attesting Environment inside the "security kernel" and potentially subject to FIPS 140-3
or Common Criteria validation and change control. For both security and compliance reasons,
there is an incentive for the generation and parsing logic to be simple and easy to implement
correctly. Additionally, when the data formats contained in this specification are parsed
within an HSM boundary -- that would be parsing Evidence
produced by a different HSM -- implementers SHOULD opt for simple logic that rejects any
data that does not match the expected format, instead of attempting to be flexible.

In particular, the Attesting Environment SHOULD generate Evidence from scratch. The Attesting Environment MUST generate Evidence
only from information and measurements that are directly observable by it.

This profile permits a restricted CMS encoder and parser; it does not require
all CMS content types or features inside the HSM security kernel. Generation
and verification have different implementation needs. Certificate collection
and outer-envelope assembly MAY occur outside the privileged component where
the architecture preserves the trusted binding described in the generation
procedure. Arbitrary caller-supplied content or digests MUST NOT be accepted
for AK signing as Evidence.

Signed attributes, their canonical encoding, and the additional content-digest
step introduce implementation costs. Whether those costs outweigh reuse of
existing CMS code depends on the security boundary and supported algorithms;
this document makes no measured code-size or performance claim.

## Privacy and Evidence Encryption {#sec-cons-privacy}

Some HSMs have the capacity of supporting cryptographic keys controlled by separate entities referred to as "tenants", and when the HSM is used in that mode
it is referred to as a multi-tenant configuration.

For example, an enterprise-grade HSM in a large multi-tenant cloud service could host TLS keys fronting multiple un-related web domains. Providing Evidence for
claims of any one of the keys would involve a Presenter that could potentially access any of the hosted keys.
In such a case, privacy violations could occur if the Presenter was to disclose information that does not relate to the subject key.

Implementers SHOULD avoid over-disclosure of information by authenticating and authorizing the entity that initiates Evidence generation and by including only
keys and portions of the Target Environment that this entity is authorized to access. The interface for selecting the elements and claims included in Evidence
is outside the scope of this specification.

A Presenter SHOULD review Evidence before disclosure and SHOULD NOT disclose Evidence containing information that the intended Verifier is not authorized to receive.
This specification does not provide Evidence encryption; deployments that require confidentiality MUST use an appropriate conveyance protocol or object-security mechanism.

{{I-D.ounsworth-rats-privacy-framework}} presents a framework for identifying points in an Evidence conveyance protocol where designers and implementers need to be conscious of privacy concerns.
For the evidence mechanism specified in this document, the primary privacy concern has to do with authenticating the Presenter against the HSM's local policies, and only releasing claims that they are authorized to view.
The means by which a Presenter requests the generation of Evidence is not covered by this specification and is left to the implementers.

Additionally, {{I-D.ounsworth-rats-privacy-framework}} calls for object-level evidence encryption (instead of relying solely on transport encryption), and corresponding validation
of the provided Verifyier encryption certificate against local policies. Such a mechanism is left out-of-scope in this specification since it is largely independent of the Evidence
formatting structures defined in this specification. Implementers are welcome to wrap the structures defined here in such an encryption layer either within the HSM or externally to the HSM
at an entity such as the Presenter.

## Authenticating and Authorizing the Presenter {#sec-cons-auth-the-presenter}

The Presenter represents a privileged role because it can learn about the existence of user keys and their protection properties, as well as details of the platform.
It can also decide whether to disclose generated Evidence to a Verifier.

For personal cryptographic tokens it might be appropriate for the local Evidence-generation interface to be unauthenticated. For enterprise and cloud-services grade HSMs,
the entity invoking that interface SHOULD be authenticated using the HSM's native authentication mechanism. The details of this interface are HSM-specific and outside the
scope of this specification.

The HSM MUST enforce its native access controls when generating Evidence. An authenticated application SHOULD be allowed to obtain Evidence only for user keys that it
is authorized to access. An administrative application that obtains Evidence for keys it is not allowed to use MUST have a distinct permission and MUST be limited to keys
for which it has administrative visibility.

## Proof-of-Possession of User Keys

With asymmetric keys within a Public Key Infrastructure (PKI) it is common to require a key holder to prove that they are in control of the private key by using it. This is
called "proof-of-possession (PoP)". This specification intentionally does not provide a mechanism for PoP of user keys and relies on the Presenter, Verifier, and Relying Party
trusting the Attester to correctly report the cryptographic keys that it is holding.

It would be trivial to add a PoP Key claim that uses the attested user key to sign over, for example, the Transaction Element. However, this approach leads to undesired consequences, as explained
below.

First, a user key intended for TLS, as an example, SHOULD only be used with the TLS protocol. Introducing a signature oracle whereby the TLS application key is used to sign Evidence could lead to cross-protocol attacks.
In this example, an attacker could submit a "nonce" value which is in fact not random but is crafted in such a way as to appear as a valid message in some other protocol context or exploit some other weakness in the signature algorithm.

Second, the Presenter that initiates Evidence generation may have permission to list the relevant application keys but not permission to use them,
as in the case where the Presenter is an administrative UI displaying HSM status information to a system's administrator or auditor.

Requiring the Attesting Environment to use the reported application keys to generate Evidence could, in some architectures, require the Attesting Environment to
resolve complex access control logic and handle complex error conditions, which violates the "simple to implement" design principle outlined in {{sec-cons-simple}}.
More discussions on authenticating the Presenter can be found in {{sec-cons-auth-the-presenter}}.

## Timestamps and HSMs {#sec-cons-hsm-timestamps}

It is common for HSMs to have an inaccurate system clock. Most clocks have a natural drift and must be corrected periodically. HSMs, like any other devices,
are subject to these issues.

There are many situations where HSMs can not naturally correct their internal system clocks. For example, consider a HSM hosting a trust anchor and usually kept offline
and booted up infrequently in a network without a reliable time management service. Another example is a smart card which boots up only when held against an NFC reader.

When a timestamp generated from a HSM is evaluated, the expected behavior of the system clock SHOULD be considered.

More specifically, the timestamp SHOULD NOT be relied on for establishing the freshness of the Evidence generated by a HSM. Instead, Verifiers SHOULD rely on other provisions
such as the "nonce" claim of the "transaction" element, introduced in this specification.

Furthermore, the internal system clock of HSMs SHOULD NOT be relied on to enforce expiration policies.
--- back

# Samples {#sec-cms-samples}

The following examples use CMS envelopes and signing certificates generated
specifically for this comparison version. The transaction, platform, and key
claims are based on the corresponding repository examples, with AK claims
updated to the signing keys below. The examples use the temporary Evidence
arc `1.3.6.1.5.5.999`, Attestation EKU `1.3.6.1.5.5.7.3.999`, and content type
`1.3.6.1.5.5.999.3.0`. These are local test values, not assigned OIDs.

The repository's existing reference implementations produce the draft-specific
envelope. They must be adapted before they can generate or verify this CMS
profile. Existing `EVIDENCE` PEM files are not CMS test vectors.

The examples chain to this test root, which the Verifier must configure
separately as a trust anchor:

~~~
{::include sampledata/cms/ca.crt}
~~~

## Simple Platform Evidence

This example reports transaction and platform elements. It uses one
ECDSA-with-SHA-256 AK, carries the AK certificate, and identifies that
certificate by issuer and serial number. It replaces the key-ID-only example
because that mode is outside the certificate-based profile.

~~~
{::include sampledata/cms/evidence1.pem}
~~~

The decoded structure and claims are:

~~~
{::include sampledata/cms/evidence1.pp}
~~~

## Key Attestation Evidence

This example reports two application keys and a short platform element. It
uses distinct ECDSA-with-SHA-256 and RSA-with-SHA-256 AKs certified under the
same Attester subject DN. Both signing certificates are included, and both
signatures protect the same content. The transaction contains an `ak-spki`
claim for each AK. It uses the base alternative-signature profile, without
RFC 5752 cross-references or optional exact certificate binding.

~~~
{::include sampledata/cms/evidence2.pem}
~~~

The decoded structure and claims are:

~~~
{::include sampledata/cms/evidence2.pp}
~~~

# Acknowledgements

This specification is the work of a design team created by the chairs
of the RATS working group. This specification has been developed
based on discussions in that design team and also with great amounts of
input taken from discussions on the RATS mailing list.

We would like to thank Jeff Andersen for the review comments.

We would like to thank Dave Thaler for his guidance.


--- back

# Changes from the Draft-Specific Envelope {#sec-cms-changes}

This editorial appendix supports comparison with
`draft-ietf-rats-pkix-key-attestation.md` and can be removed before publication.

| Area | Effect of using the CMS profile |
| --- | --- |
| Use cases, Presenter role, information model | Retained; the envelope choice does not change their purpose. |
| Elements, claims, and claim OIDs | Retained, including `TbsEvidence.version = 1`, AK claims, nonce handling, and all platform and user-key properties. |
| Envelope ASN.1 | Replace custom `Evidence`, `SignatureBlock`, and `SignerIdentifier` definitions with a CMS `ContentInfo` alias and a content-type registration. The claim module is otherwise retained. |
| CMS restrictions | Add explicit rules for content and versions, DER, certificates, signed attributes, digest sets, and excluded CMS features. |
| Signer modes | This version requires included X.509 signing certificates; SPKI-only and arbitrary key-ID-only modes need a future profile. |
| Signatures | Replace direct signatures over `TbsEvidence` with CMS signatures over signed attributes authenticating its digest and content type. |
| Algorithm and certificate binding | Require `cmsAlgorithmProtect`; permit `SigningCertificateV2` and require it when deployment policy needs exact certificate binding. |
| Multiple AKs and identity | Retain alternative signatures and distinct SPKIs; make the trusted naming context for equal DNs explicit. |
| Signature-set completeness | Keep the base at-least-one acceptance rule; describe an optional reverse AK-list check and an optional RFC 5752 variant. Neither implies all signatures must verify. |
| Certificate requirements | Retain Attestation EKU and digitalSignature KU; move certificate carriage into the CMS certificate set. |
| Encoding and processing | Use the `CMS` textual label and CMS generation and verification procedures while retaining claim validation and appraisal. |
| IANA and references | Add a content-type OID and a distinct alternative module name; reuse standardized CMS attribute OIDs and add their references. |
| Security considerations | Add algorithm, certificate, and context binding; describe a restricted CMS implementation and the trusted generation boundary. |
| Samples | Replace bespoke envelope samples with CMS examples, including parallel signatures; use separate test certificates and temporary OIDs. |

The main change is therefore to the cryptographic envelope and its processing.
Most of the attestation-specific content remains. The shorter custom envelope
ASN.1 is replaced by imports and additional CMS profile rules; the result is
not necessarily a shorter specification. This version also exposes a scope
decision about certificate-free operation that must be settled before claiming
full functional equivalence.

As an editorial size comparison, the main-body Markdown source before the
Samples section grows from about 9,500 to 11,100 whitespace-separated words
(approximately 17 percent). This includes the comparison-status note and code
fragments, but excludes the abstract, included files, samples, and this
appendix. The ASN.1 module shrinks from 343 to 324 lines. These counts describe
specification size, not implementation size or performance.
