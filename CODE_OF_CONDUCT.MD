# MediScribe Code of Conduct

## Our Pledge

We as members, contributors, and maintainers of the MediScribe project pledge to make participation in this project a harassment-free experience for everyone, regardless of age, body size, visible or invisible disability, ethnicity, sex characteristics, gender identity and expression, level of experience, education, socio-economic status, nationality, personal appearance, race, caste, colour, religion, or sexual identity and orientation.

We pledge to act and interact in ways that contribute to an open, welcoming, diverse, inclusive, and healthy project environment.

MediScribe is built for use in healthcare settings that serve vulnerable people in low-resource environments. We therefore carry an additional responsibility: our work must be technically sound, ethically grounded, and clinically safe. We pledge to uphold these standards in every contribution, discussion, and decision.

---

## Our Standards

Examples of behaviour that contribute to a positive environment include:

- Demonstrating empathy and kindness toward other contributors and the clinicians and patients who depend on this software
- Being respectful of differing opinions, viewpoints, and levels of clinical or technical experience
- Giving and gracefully accepting constructive feedback
- Accepting responsibility and apologising to those affected by our mistakes, and learning from the experience
- Prioritising patient safety and clinician trust above feature velocity or convenience
- Raising concerns about safety, regulatory, or ethical implications promptly and in good faith

Examples of unacceptable behaviour include:

- The use of sexualised language or imagery, and sexual attention or advances of any kind
- Trolling, insulting or derogatory comments, and personal or political attacks
- Public or private harassment
- Publishing others' private information, such as a physical or email address, without their explicit permission
- Weakening, bypassing, or removing safety controls — including runtime validation, forbidden-phrase detection, clinician review gates, or output-blocking mechanisms — without documented clinical justification and project maintainer approval
- Introducing changes that could cause AI-generated content to be presented as clinically authoritative without mandatory human review
- Other conduct that could reasonably be considered inappropriate in a professional healthcare or software development context

---

## Enforcement Responsibilities

MediScribe project maintainers are responsible for clarifying and enforcing our standards of acceptable behaviour and will take appropriate and fair corrective action in response to any behaviour that they deem inappropriate, threatening, offensive, or harmful.

Project maintainers have the right and responsibility to remove, edit, or reject comments, commits, code, wiki edits, issues, and other contributions that are not aligned with this Code of Conduct, and will communicate reasons for moderation decisions when appropriate.

---

## Scope

This Code of Conduct applies within all MediScribe project spaces, including the GitHub repository, issue tracker, pull requests, discussions, and any other channels managed by the project. It also applies when an individual is officially representing the MediScribe project in public spaces, such as using an official email address, posting via an official social media account, or acting as an appointed representative at an online or offline event.

---

## Responsible Use of AI in Clinical Documentation

MediScribe is an AI-assisted clinical documentation support tool used by qualified healthcare professionals in real clinical environments. The AI capabilities embedded in this application carry specific legal, ethical, and clinical responsibilities. All contributors, deployers, and users of MediScribe must adhere to the principles set out in this section.

### EU AI Act Compliance (Regulation (EU) 2024/1689)

MediScribe is developed with awareness of the [EU AI Act](https://artificialintelligenceact.eu/), which establishes harmonised rules for the development, placement on the market, and use of AI systems within the European Union.

#### Risk Classification

MediScribe is designed and intended as a **clinical documentation support tool** that generates descriptive text summaries for review by qualified clinicians. It does not make diagnostic, prognostic, or therapeutic decisions, and all AI-generated outputs are gated behind mandatory clinician review.

Under Article 6(3) of the EU AI Act, an AI system that would otherwise fall within Annex III is not considered high-risk where it does not pose a significant risk of harm and operates as a preparatory or assistive task with proper human review. MediScribe's architecture — fail-closed safety validation, mandatory clinician sign-off, descriptive-only output constraints — is designed to remain within this derogation.

Notwithstanding, Article 6(4) requires that any provider relying on Article 6(3) must document this assessment in technical documentation before deployment. Any organisation deploying MediScribe bears this documentation obligation and must conduct their own classification assessment in accordance with their specific deployment context.

If MediScribe is integrated into a system that qualifies as a medical device under EU MDR 2017/745 (see below), it may become subject to high-risk AI obligations under Article 6(1). Contributors must not introduce features that shift the system's intended purpose toward clinical decision support, diagnosis, or treatment recommendation, as this would trigger MDR qualification.

#### Article 50 Transparency Obligations

As a provider of an AI system that generates text content presented to healthcare professionals, the following transparency obligations under Article 50 (applicable from 2 August 2026) apply:

1. **AI-generated content labelling.** All AI-generated drafts — including SOAP note content, imaging findings summaries, and lab result extractions — must be clearly presented to users as AI-generated drafts pending clinician review. Contributors must not introduce UI or UX changes that obscure the AI-generated origin of content before review (Article 50(1)).

2. **Machine-readable provenance marking.** AI-generated text outputs should carry machine-readable provenance metadata indicating their artificial origin, as technically feasible (Article 50(2)). The existing `SOAPMetadata.modelVersion`, `Finding.createdAt`, and FHIR `Provenance` resources contribute to this; new generation pathways must maintain equivalent attribution.

3. **Clinician editorial responsibility.** The mandatory clinician review and signing mechanism satisfies the requirement that AI-generated content used in a professional context be subject to human review with editorial responsibility assigned (Article 50(4) context). This gate must not be weakened or removed.

#### Contributor Obligations Under the EU AI Act

All contributors must:

- Preserve or strengthen the existing safety validation architecture; never weaken runtime safety checks
- Document the capabilities and limitations of any new AI-assisted feature, including potential failure modes
- Assess and document the potential for misuse when proposing features that expand the scope of AI-generated clinical content
- Ensure new generation pathways include provenance attribution sufficient for Article 50(2) compliance

---

### EU Medical Device Regulation (MDR 2017/745) and MDCG 2019-11

MediScribe's intended purpose is clinical **documentation support** — structuring, transcribing, and formatting clinical information entered or reviewed by a qualified clinician. As assessed against the qualification framework in [MDCG 2019-11](https://health.ec.europa.eu/system/files/2020-09/md_mdcg_2019_11_guidance_en_0.pdf), software that stores, formats, or structures clinical data without providing interpretive information used to make clinical decisions does not qualify as a medical device under MDR Article 2(1).

This classification depends entirely on maintaining MediScribe's defined intended purpose. The boundary is crossed when software provides information used to take decisions with diagnostic or therapeutic purposes for a specific patient.

#### Contributor Obligations Under MDR

All contributors must:

- Not introduce features that provide diagnostic interpretations, abnormality flagging with clinical significance, treatment recommendations, or prognostic assessments — these would shift MediScribe into software as a medical device (SaMD) territory
- Not assign clinical terminology codes (ICD-10, SNOMED CT condition codes) to AI-generated content in a way that implies diagnostic classification
- Raise a discussion issue before proposing any feature that could be construed as clinical decision support, so the MDR implications can be assessed prior to implementation

---

### Data Protection and GDPR Compliance (Regulation (EU) 2016/679)

Clinical notes, imaging findings, laboratory results, and referral documentation processed by MediScribe constitute **special category data** under GDPR Article 9(1) ("data concerning health"). Their processing is subject to heightened protections.

1. **Legal basis for health data processing.** Processing of health data through MediScribe is most appropriately grounded in Article 9(2)(h) — processing necessary for the purposes of medical diagnosis, the provision of healthcare, or the management of health systems — combined with an Article 6 legal basis appropriate to the deployment context. Healthcare institutions deploying MediScribe must establish and document their legal basis before deployment.

2. **Data Protection Impact Assessment (DPIA).** Deploying MediScribe in any context that involves processing health data with AI constitutes processing of special category data using new technology in a way likely to result in high risk under Article 35(1). Deployers must conduct a DPIA before deployment. The DPIA must address: description of processing, necessity and proportionality, risks to the rights and freedoms of patients, and mitigation measures.

3. **Privacy by design and by default (Article 25).** MediScribe's offline-first, on-device architecture directly implements data protection by design: health data is not transmitted to external servers without explicit user action. Contributors must not introduce features that transmit patient data to external services, require cloud connectivity for core functionality, or persist data beyond the minimum necessary retention period. Any new data fields containing patient-identifiable information must be assessed for necessity before implementation.

4. **Data minimisation.** Clinical records should contain only the data necessary for the specific documentation purpose. Contributors must not introduce unnecessary collection of personal or health data as part of new features.

5. **Pseudonymisation.** MediScribe uses pseudonymous patient identifiers rather than real names by default. The FHIR export layer excludes patient names unless explicitly configured by the clinician. This design must be preserved.

6. **Cross-border export considerations.** The FHIR R4 export feature is designed to support EU-region interoperability standards (IPS, EU Lab IG, EHDS). When configuring or extending FHIR export for deployment outside the EU, deployers must assess whether data transfer mechanisms comply with GDPR Chapter V.

---

### MedGemma and General-Purpose AI (GPAI) Model Compliance

MediScribe integrates [MedGemma](https://developers.google.com/health-ai-developer-foundations/medgemma) as an on-device GPAI model. MedGemma is provided by Google and is not trained, modified, or distributed by the MediScribe project. The following principles govern its use.

1. **Role distinction.** Under the EU AI Act, Google is the GPAI model provider (Article 53 obligations) and MediScribe's developer is the AI system provider. Contributors to MediScribe bear AI system provider obligations; GPAI provider obligations (technical documentation, copyright compliance policy) rest with Google.

2. **Model documentation.** Deployers and contributors should be aware that MedGemma is governed by the [Health AI Developer Foundations Terms of Use](https://developers.google.com/health-ai-developer-foundations/terms), which imposes healthcare-specific restrictions on use. These restrictions may qualify as conditions that flow through to downstream deployments. All contributors and deployers must review and comply with these terms.

3. **No circumvention of model safeguards.** Contributors must not attempt to bypass, disable, or circumvent safety measures, guardrails, or usage policies implemented by Google in MedGemma. This includes prompt injection techniques, adversarial inputs designed to elicit prohibited outputs, or fine-tuning approaches that remove safety constraints.

4. **Known limitations.** MedGemma, like all large language models, can produce inaccurate, inconsistent, or hallucinated outputs. MediScribe's safety architecture — schema validation, forbidden phrase detection, mandatory clinician review — is designed to intercept unsafe outputs. Contributors must not reduce the effectiveness of these mechanisms in response to model limitations.

---

### Clinical Safety Obligations

MediScribe operates in environments where documentation errors can have real consequences for patient care. The following clinical safety obligations are non-negotiable.

1. **Safety architecture is inviolable.** The runtime safety gate — schema validation, mandatory limitations statements, forbidden phrase detection, fail-closed output blocking, and mandatory clinician review — must not be weakened in any contribution. Any change to `FindingsValidator`, `LabResultsValidator`, or `SOAPNoteValidator` that reduces their sensitivity requires explicit clinical justification, documented review by a qualified clinician, and project maintainer approval.

2. **Fail closed.** Where safe output cannot be generated, the system must block output and prompt manual documentation. Contributors must not introduce fallback paths that present unsafe or unvalidated AI output to clinicians when the primary validation path fails.

3. **Human review is mandatory.** The clinician review and signing mechanism is a regulatory and ethical requirement, not a UX feature. It must remain in place for all AI-generated content. Contributions that allow AI-generated content to be saved, shared, or exported without confirmed clinician review will not be accepted.

4. **Descriptive language only.** AI-generated clinical content must remain observational and descriptive. AI systems must not generate diagnostic, probabilistic, or prescriptive language. This constraint is enforced at runtime; contributors must not add new content templates, prompts, or generation pathways that produce diagnostic interpretations.

5. **Limitations statements are mandatory.** Every AI-generated output must include the applicable limitations statement. Contributors must not remove or shorten limitations statements from any generation pathway.

---

### Prohibited Uses

The following uses of MediScribe are strictly prohibited and constitute violations of this Code of Conduct:

- **Using AI output as a diagnosis.** Presenting, recording, or communicating AI-generated findings summaries, SOAP note content, or FHIR exports as clinical diagnoses without human review and explicit clinician sign-off.
- **Bypassing the clinician review gate.** Circumventing, disabling, or removing the mandatory review mechanism through any technical means.
- **Expanding scope to decision support.** Adding features that assess clinical significance, recommend management, determine triage, or produce probability estimates for diagnoses — uses that would qualify MediScribe as a medical device under EU MDR 2017/745.
- **Re-identifying pseudonymous data.** Combining pseudonymous patient identifiers with external data sources to re-identify individual patients.
- **Unauthorised secondary use of patient data.** Using patient health records processed by MediScribe for purposes beyond the original clinical documentation purpose without a valid legal basis.
- **Processing data without lawful basis.** Deploying MediScribe to process health data without establishing a valid GDPR Article 9(2) legal basis, conducting the required DPIA, or complying with applicable national health data legislation.
- **Misrepresenting clinical accuracy.** Presenting MediScribe's AI capabilities as clinically validated, diagnostic, or superior to clinician judgment in any communication, documentation, or marketing context.
- **Deploying without qualified oversight.** Using MediScribe in a context where AI-generated content cannot be reviewed by a qualified healthcare professional before use.
- **Prohibited AI practices.** Any use falling within the prohibited practices defined in Article 5 of the EU AI Act, including subliminal manipulation, exploitation of vulnerabilities, or social scoring.

---

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behaviour, including violations of the Responsible Use provisions above, may be reported to the MediScribe project maintainers. All complaints will be reviewed and investigated promptly and fairly.

All project maintainers are obligated to respect the privacy and security of the reporter of any incident.

---

## Enforcement Guidelines

Project maintainers will follow these guidelines in determining the consequences for any action deemed in violation of this Code of Conduct.

### 1. Correction

**Project Impact:** Use of inappropriate language or other behaviour deemed unprofessional or unwelcome in the project community.

**Consequence:** A private, written communication from project maintainers clarifying the nature of the violation and explaining why the behaviour was inappropriate. A public acknowledgement may be requested.

### 2. Warning

**Project Impact:** A violation through a single incident or series of actions, including minor safety-related changes made without adequate justification.

**Consequence:** A formal warning with consequences for continued behaviour. No unsolicited interaction with the people involved, including those enforcing the Code of Conduct, for a specified period. Violating these terms may lead to a temporary or permanent ban.

### 3. Temporary Ban

**Project Impact:** A serious violation of project standards, including introducing changes that weaken safety controls, bypass clinician review, or violate the data protection provisions in this Code of Conduct.

**Consequence:** A temporary ban from all interaction or public communication within the MediScribe project for a specified period. No public or private interaction with the people involved during this period. Violating these terms may lead to a permanent ban.

### 4. Permanent Ban

**Project Impact:** A pattern of violation of project standards, including repeated attempts to weaken clinical safety controls, deliberate misuse of AI capabilities in violation of the Prohibited Uses section, or conduct that poses a demonstrable risk to patient safety or data protection.

**Consequence:** A permanent ban from any public interaction within the MediScribe project.

---

## Legal References

- **EU AI Act** — Regulation (EU) 2024/1689 of the European Parliament and of the Council of 13 June 2024 laying down harmonised rules on artificial intelligence. [Full text](https://artificialintelligenceact.eu/).
- **Article 6 (Risk classification)** — [Classification rules for high-risk AI systems](https://artificialintelligenceact.eu/article/6/).
- **Article 50 (Transparency obligations)** — [Transparency obligations for providers and deployers of certain AI systems](https://artificialintelligenceact.eu/article/50/).
- **Article 53 (GPAI model obligations)** — [Obligations for providers of general-purpose AI models](https://artificialintelligenceact.eu/article/53/).
- **GDPR** — Regulation (EU) 2016/679 of the European Parliament and of the Council of 27 April 2016 on the protection of natural persons with regard to the processing of personal data. [Full text](https://gdpr-info.eu/).
- **GDPR Article 9 (Special category data)** — [Processing of special categories of personal data](https://gdpr-info.eu/art-9-gdpr/).
- **GDPR Article 25 (Privacy by design)** — [Data protection by design and by default](https://gdpr-info.eu/art-25-gdpr/).
- **GDPR Article 35 (DPIA)** — [Data protection impact assessment](https://gdpr-info.eu/art-35-gdpr/).
- **EU MDR 2017/745** — Regulation (EU) 2017/745 on medical devices. [EUR-Lex full text](https://eur-lex.europa.eu/eli/reg/2017/745/oj/eng).
- **MDCG 2019-11** — Qualification and classification of software under MDR 2017/745. [Guidance document](https://health.ec.europa.eu/system/files/2020-09/md_mdcg_2019_11_guidance_en_0.pdf).
- **MDCG 2025-6** — Interplay between the EU AI Act and MDR. [Guidance document](https://health.ec.europa.eu/document/download/b78a17d7-e3cd-4943-851d-e02a2f22bbb4_en).
- **MedGemma Terms of Use** — [Health AI Developer Foundations Terms of Use](https://developers.google.com/health-ai-developer-foundations/terms).
- **EDPB Guidelines 4/2019** — Guidelines on Article 25 Data Protection by Design and by Default. [EDPB document](https://www.edpb.europa.eu/sites/default/files/files/file1/edpb_guidelines_201904_dataprotection_by_design_and_by_default_v2.0_en.pdf).
- **GPAI Code of Practice** — [Final version](https://code-of-practice.ai/).

---

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant](https://www.contributor-covenant.org), version 2.1, available at [https://www.contributor-covenant.org/version/2/1/code_of_conduct.html](https://www.contributor-covenant.org/version/2/1/code_of_conduct.html). The Responsible Use of AI in Clinical Documentation section is original to the MediScribe project and incorporates requirements from the EU AI Act (Regulation (EU) 2024/1689), GDPR (Regulation (EU) 2016/679), EU MDR 2017/745, and MDCG 2019-11.

---

**Last updated:** February 2026
