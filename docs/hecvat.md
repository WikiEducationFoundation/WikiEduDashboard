# HECVAT 4.1.6 (Core) — Wiki Education Dashboard

> **About this response.** This is the official **HECVAT 4.1.6** critical-question
> ("Core") set, © EDUCAUSE, answered for the Wiki Education Dashboard's Canvas
> integration — an integration that is new and still changing. Answers were drafted
> with Claude Code, an AI assistant, from the public codebase and Wiki Education's
> infrastructure details, then reviewed and confirmed by Wiki Education (Sage Ross,
> Chief Technology Officer).

This is a Higher Education Community Vendor Assessment Toolkit (HECVAT) response for the Wiki Education Dashboard's Canvas (LTI 1.3) integration, covering the **critical ("Core") questions** — the asterisked subset EDUCAUSE recommends for a Lite-style review. (Full HECVAT 4 has 332 questions across seven tabs; this Core answers the critical and identification questions.) Answers use **Yes / No / N/A**; the Notes field is optional context.

Sections such as HIPAA, PCI DSS, and Consulting Services apply only if the product handles those categories; where they don't apply they are marked N/A (verify).


## General Information

**GNRL-01** — Solution Provider Name

**Answer:** Wiki Education Foundation

**GNRL-02** — Solution Name

**Answer:** Wiki Education Dashboard

**GNRL-03** — Solution Description

**Answer:** The Wiki Education Dashboard is an open-source, hosted (cloud-based) web application (github.com/WikiEducationFoundation/WikiEduDashboard) that helps instructors and students manage Wikipedia and other Wikimedia writing assignments — tracking contributions, delivering training modules and exercises, and reporting progress. **This assessment covers the Dashboard as used by an institution through its Canvas LTI 1.3 integration:** the integration syncs the Canvas roster (via NRPS) and reports training/exercise progress back to the Canvas gradebook (via AGS), while the Dashboard itself — its hosting, storage, and security — is where the institution's data is received and handled.

**GNRL-04** — Solution Provider Contact Name

**Answer:** Sage Ross

**GNRL-05** — Solution Provider Contact Title

**Answer:** Chief Technology Officer, Wiki Education

**GNRL-06** — Solution Provider Contact Email

**Answer:** sage@wikiedu.org

**GNRL-07** — Solution Provider Contact Phone Number

**Answer:** N/A

**Notes:** Wiki Education does not offer phone-based support in this context; the contact email (GNRL-06) is the point of contact.

**GNRL-08** — Country of Company Headquarters

**Answer:** United States

**GNRL-09** — Employee Work Locations (all)

**Answer:** United States (all employees are based in the United States)


## Documentation

**DOCU-01** — Do you have a well-documented business continuity plan (BCP), with a clear owner, that is tested annually?

**Answer:** No

**Notes:** Wiki Education does not have a business continuity plan.

**DOCU-02** — Do you have a well-documented disaster recovery plan (DRP), with a clear owner, that is tested annually?

**Answer:** No

**Notes:** Wiki Education maintains a disaster recovery plan, but it is not tested annually.


## Assessment of Third Parties

**THRD-01** — Do you perform security assessments of third-party companies with which you share data (e.g., hosting providers, cloud services, PaaS, IaaS, SaaS)?

**Answer:** No

**THRD-02** — Do you have contractual language in place with third parties governing access to institutional data?

**Answer:** No

**Notes:** Wiki Education has not negotiated custom data-protection contracts with its subprocessors; each is used under its standard terms of service and privacy policy. Institutional data from Canvas (roster and grades) does not reach Mailgun, which handles only the Dashboard's own email.

**THRD-03** — Do the contracts in place with these third parties address liability in the event of a data breach?

**Answer:** No

**THRD-04** — Do you have an implemented third-party management strategy?

**Answer:** No


## Change Management

**CHNG-01** — Will the institution be notified of major changes to your environment that could impact the institution's security posture?

**Answer:** No

**CHNG-02** — Does the system support client customizations from one release to another?

**Answer:** No

**CHNG-03** — Do you have an implemented system configuration management process (e.g., secure "gold" images, etc.)?

**Answer:** No


## Policies, Processes, and Procedures

**PPPR-01** — Do you have a documented patch management process?

**Answer:** No

**PPPR-02** — Can your organization comply with institutional policies on privacy and data protection with regard to users of institutional systems, if required?

**Answer:** No

**Notes:** As a small nonprofit, Wiki Education will make reasonable efforts to accommodate an institution's privacy and data-protection requirements within its capacity, but cannot commit to fully complying with all institutional policies.

**PPPR-03** — Is your company subject to the institution's geographic region's laws and regulations?

**Answer:** Yes

**Notes:** Wiki Education is a U.S.-based organization governed by U.S. federal and California state law.


## Required Questions

**REQU-01** — Are you offering a cloud-based product?

**Answer:** Yes

**REQU-02** — Does your product or service have an interface?

**Answer:** Yes

**REQU-03** — Are you providing consulting services?

**Answer:** No

**REQU-04** — Does your solution have AI features, or are there plans to implement AI features in the next 12 months?

**Answer:** Yes

**Notes:** Wiki Education develops no generative AI and hosts no AI model of its own. As part of normal operation the Dashboard calls two third-party machine-learning services, both only on public Wikipedia content and neither on institutional data: Wikimedia's article-quality models (ORES/LiftWing), to display an article's quality rating, and the Pangram API, to flag suspected LLM-generated text in a student's Wikipedia edits. Wiki Education staff also have an admin-only page for evaluating AI-detection services against public Wikipedia text on demand; it is used rarely, by staff only, and is not part of any course workflow.

**REQU-05** — Does your solution process protected health information (PHI) or any data covered by the Health Insurance Portability and Accountability Act (HIPAA)?

**Answer:** No

**REQU-06** — Is the solution designed to process, store, or transmit credit card information?

**Answer:** No

**REQU-07** — Does operating your solution require the institution to operate a physical or virtual appliance in their own environment or to provide inbound firewall exceptions to allow your employees to remotely administer systems in the institution's environment?

**Answer:** No

**REQU-08** — Does your solution have access to personal or institutional data?

**Answer:** Yes

**Notes:** The integration is designed around Canvas's Anonymized data-sharing model: the only Canvas data it requires or saves for each student is that student's Canvas ID (an opaque LMS user id), their role in the course, and their enrollment status in the course (active, inactive, or deleted). Canvas's privacy setting governs what a launch and roster sync actually transmit, and where it is set to something more permissive the Dashboard neither uses nor stores the additional fields — names and email addresses are discarded on receipt. A student's identity (name, Wikipedia account) comes from the student's own Wikipedia login on the Dashboard, not from Canvas; the Dashboard stores only the link between the Canvas ID and the Dashboard account, and returns grades/scores. For each linked course, the Dashboard also stores a course-level configuration record: the Canvas course's ID and name, the institution's Canvas URL, and the LTI service endpoints and per-course credential used for roster and grade sync — institutional configuration data rather than student data.


## Authentication, Authorization, and Account Management

**AAAI-01** — Does your solution support single sign-on (SSO) protocols for user and administrator authentication?

**Answer:** Yes

**Notes:** The Canvas integration uses LTI 1.3, which provides single sign-on from the LMS; the Dashboard's own accounts authenticate via Wikimedia OAuth.

**AAAI-02** — For customers not using SSO, does your solution support local authentication protocols for user and administrator authentication?

**Answer:** N/A

**Notes:** The Dashboard offers no non-SSO authentication option; all authentication is via SSO (LTI 1.3 from the LMS and Wikimedia OAuth), so the non-SSO password questions do not apply.

**AAAI-03** — For customers not using SSO, can you enforce password/passphrase complexity requirements (provided by the institution)?

**Answer:** N/A

**Notes:** The Dashboard offers no non-SSO authentication option; all authentication is via SSO (LTI 1.3 from the LMS and Wikimedia OAuth), so the non-SSO password questions do not apply.

**AAAI-04** — For customers not using SSO, does the system have password complexity or length limitations and/or restrictions?

**Answer:** N/A

**Notes:** The Dashboard offers no non-SSO authentication option; all authentication is via SSO (LTI 1.3 from the LMS and Wikimedia OAuth), so the non-SSO password questions do not apply.

**AAAI-05** — For customers not using SSO, do you have documented password/passphrase reset procedures that are currently implemented in the system and/or customer support?

**Answer:** N/A

**Notes:** The Dashboard offers no non-SSO authentication option; all authentication is via SSO (LTI 1.3 from the LMS and Wikimedia OAuth), so the non-SSO password questions do not apply.

**AAAI-06** — Does your organization participate in InCommon or another eduGAIN-affiliated trust federation?

**Answer:** No

**Notes:** The Dashboard does not participate in InCommon or an eduGAIN-affiliated federation; authentication is via Wikimedia OAuth.

**AAAI-07** — Are there any passwords/passphrases hard-coded into your systems or solutions?

**Answer:** No

**Notes:** Credentials/secrets are supplied via environment configuration, not hard-coded, in the open-source codebase.

**AAAI-08** — Are you storing any passwords in plaintext?

**Answer:** No

**Notes:** The Dashboard does not store user passwords — authentication is via Wikimedia OAuth (and LTI 1.3 from the LMS).

**AAAI-09** — Are audit logs available that include AT LEAST all of the following: login, logout, actions performed, and source IP address?

**Answer:** No

**Notes:** Wiki Education does not keep dedicated audit logs. The only activity record is regularly-rotated Apache access logs (Common Log Format), which capture source IP, timestamp, and each HTTP request — but not authenticated-user login/logout events or application-level actions.

**AAAI-11** — Can you provide the institution documentation regarding the retention period for those logs, how logs are protected, and whether they are accessible to the customer (and if so, how)?

**Answer:** No

**Notes:** There are no dedicated audit logs (see AAAI-09), and Wiki Education does not maintain or provide institutions with formal documentation on access-log retention, protection, or accessibility; the access logs are not made available to institutions.


## Data

**DATA-01** — Will the institution's data be stored on any devices (database servers, file servers, SAN, NAS, etc.) configured with non-RFC 1918/4193 (i.e., publicly routable) IP addresses?

**Answer:** Yes

**Notes:** The Dashboard runs on a single server (Linode, Fremont CA) that hosts the web application and the database together; as the public web server it has a publicly routable IP. The database is reached locally by the co-located application and is not exposed as a separate internet-facing service.

**DATA-02** — Is the transport of sensitive data encrypted using security protocols/algorithms (e.g., system-to-client)?

**Answer:** Yes

**Notes:** All Dashboard traffic is served over HTTPS/TLS (system-to-client and system-to-system).

**DATA-03** — Is the storage of sensitive data encrypted using security protocols/algorithms (e.g., disk encryption, at-rest, files, and within a running database)?

**Answer:** No

**Notes:** The primary storage on the Linode-hosted server is not encrypted at rest; the off-site backup copies held in Dropbox are encrypted at rest by Dropbox (AES-256).

**DATA-04** — Do all cryptographic modules in use in your solution conform to the Federal Information Processing Standards (FIPS PUB 140-2 or 140-3)?

**Answer:** No

**Notes:** The solution uses the platform's standard cryptography (OpenSSL/TLS on Debian); no FIPS 140-2/140-3-validated cryptographic module is enabled.

**DATA-05** — Will the institution's data be available within the system for a period of time at the completion of this contract?

**Answer:** Yes

**DATA-06** — Are ownership rights to all data, inputs, outputs, and metadata retained even through a provider acquisition or bankruptcy event?

**Answer:** Yes

**DATA-07** — Do backups containing the institution's data ever leave the institution's data zone either physically or via network routing?

**Answer:** Yes

**Notes:** Periodic off-Linode copies of the database backups are kept in Dropbox for off-site resilience; these copies reside in Dropbox's cloud infrastructure, outside the primary Linode (Fremont, CA) hosting environment.

**DATA-08** — Is media used for long-term retention of business data and archival purposes stored in a secure, environmentally protected area?

**Answer:** Yes

**Notes:** Off-site backup copies are retained in Dropbox, whose cloud storage resides in professionally-operated, environmentally-controlled datacenters.


## Application/Service Security

**APPL-01** — Are access controls for institutional accounts based on structured rules, such as role-based access control (RBAC), attribute-based access control (ABAC), or policy-based access control (PBAC)?

**Answer:** Yes

**Notes:** Access is governed by a role/permission model: per-course roles (student, instructor, Wiki Education staff) and account permissions (instructor, admin, super-admin).

**APPL-02** — Are you using a web application firewall (WAF)?

**Answer:** No

**Notes:** The production server (a single Debian host on Linode) runs Apache + Passenger per server_config/; no web application firewall (e.g., mod_security) is configured or documented.

**APPL-03** — Are only currently supported operating system(s), software, and libraries leveraged by the system(s)/application(s) that will have access to institution's data?

**Answer:** Yes

**Notes:** The application runs on current, supported runtimes — Ruby 3.4.8 and Rails 8.1.3 — with maintained dependencies. The host OS is Debian 11 (bullseye), currently under Debian LTS; note that Debian 11 LTS support ends around August 2026, so an upgrade to a newer Debian release is due to remain on a supported version.

**APPL-04** — Does your application require access to location or GPS data?

**Answer:** No

**Notes:** The Dashboard does not use or require location or GPS data.

**APPL-05** — Does your application provide separation of duties between security administration, system administration, and standard user functions?

**Answer:** No

**Notes:** As a small nonprofit, Wiki Education does not separate system-administration and security responsibilities across distinct teams; the same small team performs both.

**APPL-06** — Do you subject your code to static code analysis and/or static application security testing prior to release?

**Answer:** Yes

**Notes:** Every CI build runs static code analysis — RuboCop (Ruby) and ESLint (JavaScript). These are code-quality/style analyzers; there is no dedicated security SAST (e.g., Brakeman) in the pipeline.

**APPL-07** — Do you have software testing processes (dynamic or static) that are established and followed?

**Answer:** Yes

**Notes:** Established and enforced in CI (.github/workflows/ci.yml): the RSpec test suite and the JavaScript test suite run on every change, alongside linting and an eager-load check.


## Datacenter

**DCTR-06** — Does a physical barrier fully enclose the physical space, preventing unauthorized physical contact with any of your devices?

**Answer:** Yes

**Notes:** The physical datacenter is operated by the hosting provider, Linode (Akamai), in Fremont, CA; physical access controls are covered by the provider's datacenter certifications (e.g., SOC 2).

**DCTR-10** — Are redundant power strategies tested?

**Answer:** Yes

**Notes:** Power redundancy is managed and tested by the hosting provider, Linode (Akamai), per their datacenter certifications.


## Firewalls, IDS, IPS, and Networking

**FIDP-01** — Are you utilizing a stateful packet inspection (SPI) firewall?

**Answer:** No

**Notes:** No firewall is configured: the documented server setup (server_config/) does not include one, and Debian ships netfilter with no active rules by default.

**FIDP-02** — Do you have a documented policy for firewall change requests?

**Answer:** No

**Notes:** No firewall, and no documented firewall-change policy.

**FIDP-03** — Have you implemented an intrusion detection system (network-based)?

**Answer:** No

**Notes:** No network-based intrusion detection system is deployed or documented; not a Debian default.

**FIDP-04** — Do you employ host-based intrusion detection?

**Answer:** No

**Notes:** No host-based intrusion detection (e.g., AIDE, OSSEC) is installed or documented; not a Debian default.

**FIDP-05** — Are audit logs available for all changes to the network, firewall, IDS, and IPS systems?

**Answer:** No

**Notes:** No firewall/IDS/IPS systems are in place (see FIDP-01/03/04), and no dedicated audit logging of network/firewall changes is configured.


## Vulnerability Management

**VULN-01** — Are your systems and applications scanned with an authenticated user account for vulnerabilities (that are remediated) prior to new releases?

**Answer:** No

**Notes:** Vulnerability scanning is not tied to the release process. Wiki Education does perform periodic security code audits and uses GitHub security alerts (Dependabot) to surface dependency vulnerabilities, but does not run authenticated vulnerability scans as a release gate.

**VULN-02** — Will you provide results of application and system vulnerability scans to the institution?

**Answer:** Yes

**VULN-03** — Will you allow the institution to perform its own vulnerability testing and/or scanning of your systems and/or application, provided that testing is performed at a mutually agreed upon time and date?

**Answer:** Yes


## IT Accessibility

**ITAC-06** — Has a VPAT or ACR been created or updated for the solution and version under consideration within the past 12 months?

_Additional Information_

**Answer:** Yes

**Notes:** A VPAT 2.5 (WCAG edition) is published at https://dashboard.wikiedu.org/accessibility.

**ITAC-07** — Will your company agree to meet your stated accessibility standard or WCAG 2.1 AA as part of your contractual agreement for the solution?

**Answer:** N/A

**Notes:** The Canvas integration is provided without a formal contractual agreement, so there is no contract in which to include this commitment. The Dashboard's accessibility conformance is documented in its VPAT (see ITAC-06).

**ITAC-08** — Does the solution substantially conform to WCAG 2.1 AA?

**Answer:** No

**Notes:** Per the Dashboard's VPAT (see ITAC-06), the product does not claim full or substantial conformance: across the evaluated WCAG 2.1 A/AA criteria roughly half are 'Supports' and half 'Partially Supports' (none 'Does Not Support'), with known gaps including the ArticleViewer authorship view, modal focus management, the survey flow, and chart descriptions.

**ITAC-09** — Do you have a documented and implemented process for reporting and tracking accessibility issues?

**Answer:** Yes

**Notes:** Reporting is documented at https://dashboard.wikiedu.org/faq/23; accessibility issues are tracked via GitHub.


## Consulting Services

**CONS-01** — Will the consultant require access to the institution's network resources?

**Answer:** N/A

**Notes:** Not applicable: Wiki Education is not a consulting service (see REQU-03); the Dashboard is a hosted software product.

**CONS-02** — Has the consultant received training on (sensitive, HIPAA, PCI, etc.) data handling?

**Answer:** N/A

**Notes:** Not applicable: Wiki Education is not a consulting service (see REQU-03); the Dashboard is a hosted software product.

**CONS-03** — Is the data encrypted (at rest) while in the consultant's possession?

**Answer:** N/A

**Notes:** Not applicable: Wiki Education is not a consulting service (see REQU-03); the Dashboard is a hosted software product.

**CONS-04** — Can access be restricted based on source IP address?

**Answer:** N/A

**Notes:** Not applicable: Wiki Education is not a consulting service (see REQU-03); the Dashboard is a hosted software product.


## HIPAA Compliance

**HIPA-01** — Do your workforce members receive regular training related to the Health Insurance Portability and Accountability Act (HIPAA) Privacy and Security Rules and the HITECH Act?

**Answer:** N/A

**Notes:** Not applicable: the Dashboard does not process protected health information (PHI) (see REQU-05).

**HIPA-02** — Have you identified areas of risk?

**Answer:** N/A

**Notes:** Not applicable: the Dashboard does not process protected health information (PHI) (see REQU-05).

**HIPA-03** — Have the relevant policies/plans been tested?

**Answer:** N/A

**Notes:** Not applicable: the Dashboard does not process protected health information (PHI) (see REQU-05).

**HIPA-04** — Have you entered into a Business Associate Agreements with all subcontractors who may have access to protected health information (PHI)?

**Answer:** N/A

**Notes:** Not applicable: the Dashboard does not process protected health information (PHI) (see REQU-05).


## Payment Card Industry Data Security Standard (PCI DSS)

**PCID-01** — Do you have a current, executed within the past year, Attestation of Compliance (AoC) or Report on Compliance (RoC)?

**Answer:** N/A

**Notes:** Not applicable: the Dashboard does not collect, process, or store cardholder data (see REQU-06).

**PCID-02** — Is the application listed as an approved Payment Application Data Security Standard (PA-DSS) application?

**Answer:** N/A

**Notes:** Not applicable: the Dashboard does not collect, process, or store cardholder data (see REQU-06).

**PCID-03** — Does the system or solutions use a third party to collect, store, process, or transmit cardholder (payment/credit/debt card) data?

**Answer:** N/A

**Notes:** Not applicable: the Dashboard does not collect, process, or store cardholder data (see REQU-06).


## General AI Questions

**AIGN-01** — Does your solution have an AI risk model when developing or implementing your solution's AI model?

**Answer:** N/A

**Notes:** Not applicable: Wiki Education develops and hosts no AI model of its own, so there is no model development to risk-model. The third-party services it calls (Wikimedia article-quality models; the Pangram LLM-detection API) operate only on public Wikipedia content, not on institutional data — see REQU-04.

**AIGN-02** — Can your solution's AI features be disabled by tenant and/or user?

**Answer:** No

**Notes:** Neither can be switched off per institution or per user; there is no such control. Article-quality ratings are shown to everyone. LLM-detection of student edits runs only on the Wiki Education Dashboard, only for English Wikipedia, and only while a course is still running — but those are limits on where it applies, not settings an institution can change. Both services operate only on public Wikipedia content, so an institution's own data is not sent to either regardless.

**AIGN-03** — Have your staff completed responsible AI training?

**Answer:** No

**Notes:** Wiki Education staff have not completed a formal responsible-AI training programme. The AI the Dashboard uses is two traditional machine-learning classifiers — Wikimedia's article-quality models and an LLM-detection service — rather than open-ended generative AI: each takes public Wikipedia text or an article identifier and returns a score or rating, and neither generates content, takes actions, or receives institutional data. Wiki Education develops and trains no model of its own.

## AI Policy

**AIPL-01** — Are your AI developer's policies, processes, procedures, and practices across the organization related to the mapping, measuring, and managing of AI risks conspicuously posted, unambiguous, and implemented effectively?

**Answer:** N/A

**Notes:** Not applicable: this concerns an AI or LLM model that the vendor develops, trains, or hosts, and Wiki Education has none. The AI features it does have (see REQU-04) are calls to third-party services over public Wikipedia content, with no model, training data, or fine-tuning of its own.

**AIPL-02** — Have you identified and measured AI risks?

**Answer:** No

**Notes:** Wiki Education has not carried out a formal AI risk assessment. The judgement behind that: the AI it uses is two traditional machine-learning classifiers — Wikimedia's article-quality models and an LLM-detection service — not open-ended generative AI. Each takes public Wikipedia text or an article identifier and returns a score or a rating. Neither generates content, takes actions, holds a conversation, or receives institutional data, so the risks a generative system raises — prompt injection, fabricated output presented as fact, training on customer data, unbounded tool use — do not arise here.

**AIPL-03** — In the event of an incident, can your solution's AI features be disabled in a timely manner?

**Answer:** Yes

**Notes:** There is no purpose-built off switch. The operational lever is withdrawing the third-party API credential, which stops the LLM-detection calls promptly and can be done by Wiki Education at any time without a release. Article-quality ratings come from Wikimedia's own public service and would require a code change to remove. Neither service receives institutional data, so an incident at either does not expose an institution's roster, grades, or accounts.

**AIPL-04** — If disabled because of an incident, can your solution's AI features be re-enabled in a timely manner?

**Answer:** Yes

**Notes:** Restoring the withdrawn credential resumes LLM detection; no release is required.

## AI Data Security

**AISC-01** — If sensitive data is introduced to your solution's AI model, can the data be removed from the AI model by request?

**Answer:** N/A

**Notes:** Not applicable: this concerns an AI or LLM model that the vendor develops, trains, or hosts, and Wiki Education has none. The AI features it does have (see REQU-04) are calls to third-party services over public Wikipedia content, with no model, training data, or fine-tuning of its own.

**AISC-02** — Is user input data used to influence your solution's AI model?

**Answer:** N/A

**Notes:** Not applicable: this concerns an AI or LLM model that the vendor develops, trains, or hosts, and Wiki Education has none. The AI features it does have (see REQU-04) are calls to third-party services over public Wikipedia content, with no model, training data, or fine-tuning of its own.

**AISC-03** — Do you provide logging for your solution's AI feature(s) that includes user, date, and action taken?

**Answer:** Yes

**Notes:** Every LLM-detection check is recorded against the revision it examined, with the contributing user, the course, the article, the check type, whether it was run automatically or by a named staff member, and the timestamp. Results are retained with that record.

## AI Machine Learning

**AIML-01** — Do you separate ML training data from your ML solution data?

**Answer:** N/A

**Notes:** Not applicable: this concerns an AI or LLM model that the vendor develops, trains, or hosts, and Wiki Education has none. The AI features it does have (see REQU-04) are calls to third-party services over public Wikipedia content, with no model, training data, or fine-tuning of its own.

**AIML-02** — Do you authenticate and verify your ML model's feedback?

**Answer:** N/A

**Notes:** Not applicable: this concerns an AI or LLM model that the vendor develops, trains, or hosts, and Wiki Education has none. The AI features it does have (see REQU-04) are calls to third-party services over public Wikipedia content, with no model, training data, or fine-tuning of its own.


## AI Large Language Model (LLM)

**AILM-01** — Do you limit your solution's LLM privileges by default?

**Answer:** N/A

**Notes:** Not applicable: this concerns an AI or LLM model that the vendor develops, trains, or hosts, and Wiki Education has none. The AI features it does have (see REQU-04) are calls to third-party services over public Wikipedia content, with no model, training data, or fine-tuning of its own.

**AILM-02** — Is your LLM training data vetted, validated, and verified before training the solution's AI model?

**Answer:** N/A

**Notes:** Not applicable: this concerns an AI or LLM model that the vendor develops, trains, or hosts, and Wiki Education has none. The AI features it does have (see REQU-04) are calls to third-party services over public Wikipedia content, with no model, training data, or fine-tuning of its own.

**AILM-03** — Do any actions taken by your solution's LLM features or plugins require human intervention?

**Answer:** N/A

**Notes:** Not applicable: this concerns an AI or LLM model that the vendor develops, trains, or hosts, and Wiki Education has none. The AI features it does have (see REQU-04) are calls to third-party services over public Wikipedia content, with no model, training data, or fine-tuning of its own.

**AILM-04** — Do you limit multiple LLM model plugins being called as part of a single input?

**Answer:** N/A

**Notes:** Not applicable: this concerns an AI or LLM model that the vendor develops, trains, or hosts, and Wiki Education has none. The AI features it does have (see REQU-04) are calls to third-party services over public Wikipedia content, with no model, training data, or fine-tuning of its own.


## Privacy-Specific Company Details

**PCOM-01** — Have you had a personal data breach in the past three years that involved reporting to a governmental agency, notice to individuals (including voluntary notice), or notice to another organization or institution?

**Answer:** No


## Privacy of Third Parties

**PTHP-01** — Do you have contractual agreements with third parties that require them to maintain standards and to comply with all regulatory requirements?

**Answer:** No


## Privacy of Sensitive Data

**PDAT-01** — Do you collect, process, or store demographic information?

**Answer:** Yes

**Notes:** The Dashboard collects optional demographic information from students.

**PDAT-02** — Do you capture or create genetic, biometric, or behaviometric information (e.g., facial recognition or fingerprints)?

**Answer:** No

**PDAT-03** — Do you combine institutional data (including "de-identified," "anonymized," or otherwise masked data) with personal data from any other sources?

**Answer:** Yes

**Notes:** The integration's purpose requires linking two records. From Canvas it receives an opaque LMS user id, that user's role in the course, and their enrollment status in the course, and nothing else — no name and no email address. It links that id to a Wiki Education Dashboard account, which the student creates and controls themselves by logging in with their own Wikipedia account, and which may hold a real name, an email address, and optional demographic fields the student supplied to the Dashboard directly. The link is what makes the integration work: it is how Wikipedia contributions are attributed to the right student and how that student's progress is returned to the correct row of the Canvas gradebook.

Three limits on that combination: the student establishes it themselves by logging in with their own Wikipedia account, so it is not inferred or matched behind the scenes; nothing is combined with purchased, brokered, or other third-party data; and the combined record exists only in the Dashboard's own database, which is not sold, licensed, or shared for advertising.


## Privacy Policies and Procedures

**PRPO-06** — Do you have a privacy awareness/training program?

**Answer:** Yes

**Notes:** All employees complete a privacy orientation and sign a data privacy pledge.

**PRPO-12** — Do you share any institutional data with law enforcement without a valid warrant or subpoena?

**Answer:** No


## Privacy and AI

**DPAI-02** — Is any institutional data retained in AI processing?

**Answer:** No

**Notes:** What these services receive is public Wikipedia content — an article's identifiers for quality rating, and the text of a student's Wikipedia edit for LLM detection — not institutional data, and not the roster, grade, or account data an LMS integration exchanges. Detection results are stored by the Dashboard against the revision. Note for completeness that a Pangram submission also produces a report hosted by Pangram at a URL that is not access-controlled; its content is the public Wikipedia text that was submitted.

**DPAI-03** — Do you have agreements in place with third parties or subprocessors regarding the protection of customer data and use of AI?

**Answer:** No

**Notes:** Wiki Education has no negotiated data-protection agreements with its subprocessors — each is used under its standard terms of service and privacy policy (see THRD-02, PTHP-01). Subprocessors that receive personal/institutional data: Linode (Akamai) (hosting — Fremont, CA, USA), Dropbox (off-site storage of database backups, which contain institutional data), LTIAAS (LMS roster + grade passback), Mailgun (course-related email), Sentry (error monitoring; logs may include usernames, with IP addresses filtered out), and Salesforce (Wiki Education's own CRM, for courses in its programs; receives course-level records — title, course-page and dashboard URLs, dates, participant and edit counts, assignment settings, and counts of AI-detection alerts — and no student names or email addresses); authentication and edits go through Wikimedia. The machine-learning services named in REQU-04 are not in this list because what they receive is public Wikipedia content rather than personal or institutional data.
