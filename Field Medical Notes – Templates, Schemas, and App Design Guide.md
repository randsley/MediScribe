**Field Medical Notes – Templates, Schemas, and App Design Guide**  
  
This document consolidates **recommended note formats**, **field-optimized templates**, **unified data schema**, and **offline-first app design guidance** for medical documentation in scarce-resource environments.  
  
⸻  
  
**1. Design Principles for Field Medical Documentation**  
  
**Core Priorities**  
	•	**Offline-first**: All functions work without connectivity  
	•	**Fast capture**: Minimal taps, large controls, glove-friendly  
	•	**Resilient**: Autosave, crash-safe, power-efficient  
	•	**Resilient**: Autosave, crash-safe, power-efficient  
	•	**Legally defensible**: timestamps, author identity, immutable signing  
	•	**Minimal but sufficient**: capture only what matters clinically  
  
**Mandatory Data (Minimum Viable Dataset)**  
  
Always attempt to capture:  
	•	Patient identifier (temporary allowed)  
	•	Estimated age / sex at birth  
	•	Date & time (auto)  
	•	Location / setting  
	•	Chief complaint & mechanism (if trauma)  
	•	Allergies / medications (or “unknown”)  
	•	At least one set of vitals  
	•	Interventions performed with timestamps  
	•	Disposition / referral  
	•	Clinician identity  
  
⸻  
  
**2. Field Header (Universal Block for All Notes)**  
  
Include at the top of every note:  
	•	Patient ID / Temporary ID  
	•	Estimated age / sex at birth  
	•	Date & time (auto, timezone aware)  
	•	Location (free text + optional GPS)  
	•	Setting: roadside / tent / home / ambulance  
	•	Clinician name & role  
	•	Triage category (START / local system)  
	•	Consent: obtained / implied emergency / not possible  
	•	Interpreter needed (yes/no + language)  
	•	Attachments present (yes/no)  
  
⸻  
  
**3. Field-Optimized Clinical Templates**  
  
**3.1 Field SOAP (Minimum Viable SOAP)**  
  
**Header:** ID • Age • Sex • Date-Time • Location • Triage • Clinician  
  
**S — Subjective**  
**S — Subjective**  
	•	Chief complaint  
	•	Onset / duration  
	•	Severity  
	•	Mechanism / exposure  
	•	Associated symptoms  
	•	Allergies (or unknown)  
	•	Medications (or unknown)  
	•	Key risks (pregnancy, anticoagulants, seizures, diabetes)  
  
**O — Objective**  
	•	Primary survey (ABCDE or AVPU/GCS)  
	•	Vitals (partial acceptable)  
	•	Focused exam  
	•	Point-of-care tests (glucose, pregnancy, temp)  
  
**A — Assessment**  
	•	Working diagnosis  
	•	Differentials / cannot-rule-out  
	•	Red flags  
	•	Stability: stable / unstable  
  
**P — Plan**  
	•	Immediate actions  
	•	Medications given (dose / route / time)  
	•	Oxygen / fluids / immobilization  
	•	Disposition: observe / refer / transfer / evacuate  
	•	Safety-net instructions  
  
⸻  
  
**3.2 Field APSO**  
  
**A — Assessment**  
	•	Problem list with severity and stability  
	•	Key findings  
	•	Overall impression  
  
**P — Plan**  
	•	Per-problem actions  
	•	Monitoring  
	•	Disposition  
  
**S — Subjective**  
	•	Patient-reported changes  
  
**O — Objective**  
	•	Latest vitals  
	•	Exam highlights  
	•	New test results  
  
⸻  
  
**3.3 Field POMR (Minimal)**  
  
**Database**  
**Database**  
	•	Chief complaint  
	•	Baseline vitals  
	•	Key history  
  
**Problem List**  
	•	Active / resolved problems with dates  
  
**Progress per Problem (mini-SOAP)**  
	•	S: symptom update  
	•	O: key finding  
	•	A: problem status  
	•	P: next step  
  
**Goals**  
	•	1–2 key clinical targets  
  
⸻  
  
**3.4 Field SBAR (Handoff)**  
  
**S — Situation**  
	•	Patient + location  
	•	Acuity  
	•	1-line problem  
  
**B — Background**  
	•	Diagnosis / mechanism  
	•	Allergies / meds  
	•	Key comorbidities  
  
**A — Assessment**  
	•	Vitals  
	•	Exam highlights  
	•	Impression  
  
**R — Recommendation**  
	•	What you need  
	•	Urgency  
	•	Transport / isolation needs  
  
⸻  
  
**4. Unified Field Note Schema (Single Model → Multiple Views)**  
  
**Design Goals**  
	•	Capture once, render as SOAP / APSO / POMR / SBAR  
	•	Support unknown / not obtainable values  
	•	Track interventions with timestamps  
	•	Enable automatic handoff summaries  
	•	Preserve audit and legal integrity  
  
**Core JSON Schema (Simplified)**  
  
```
{
  "note": {
    "meta": {
      
```
```
"type": "FIELD_NOTE",

```
```
      "status": "draft",
      
```
```
"createdAt": "...",

```
```
      "author": { "id": "", "display": "", "role": "" },
      "patient": { "id": "temp_001", "estimatedAgeYears": 30, "sexAtBirth": "male" },
      
```
```
"encounter": { "setting": "roadside", "locationText": "Km 12" },

```
```
      
```
```
"consent": { "status": "implied_emergency" }

```
```
    },

    "triage": { "system": "START", "category": "red" },

    
```
```
"problemList": [ { "problemId": "p1", "label": "Respiratory distress", "status": "active" } ],

```
```

    
```
```
"subjective": { "chiefComplaint": "Shortness of breath" },

```
```

    
```
```
"objective": {

```
```
      "vitals": [ { "bp": {"systolic":90,"diastolic":60}, "hr":122, "rr":30, "spo2":84 } ],
      "focusedExam": { "respiratory": ["crackles"] }
    },

    
```
```
"assessment": {

```
```
      
```
```
"workingDiagnoses": [ { "label": "Pulmonary edema", "certainty": "possible" } ],

```
```
      
```
```
"stability": "unstable"

```
```
    },

    
```
```
"plan": {

```
```
      
```
```
"actionsPlanned": ["start_oxygen"],

```
```
      "disposition": { "type": "transfer", "destination": "Nearest ER", "urgency": "immediate" }
    },

    "interventions": [
      { 
```
```
"type": "oxygen", "details": "NRB 15 L/min", "performedAt": "..." }

```
```
    ],

    "handoff": { "sbar": { "S": {}, "B": {}, "A": {}, "R": {} } }
  }
}

```
  
  
⸻  
  
**5. Mapping Unified Schema to Clinical Views**  
  
**SOAP**  
	•	S → subjective  
	•	O → objective  
	•	O → objective  
	•	A → assessment  
	•	A → assessment  
	•	P → plan + interventions  
  
**APSO**  
	•	A/P first using assessment and plan  
	•	S/O collapsed afterwards  
  
**POMR**  
	•	Database → subjective + objective baseline  
	•	Problem list → problemList  
	•	Progress per problem → filtered sections by problemId  
  
**SBAR (Auto-generated)**  
	•	**S**: patient summary + triage + worst vital + chief complaint  
	•	**B**: allergies + meds + PMH + mechanism  
	•	**A**: exam highlights + working dx + stability  
	•	**R**: disposition + urgent needs + actions performed  
	•	**R**: disposition + urgent needs + actions performed  
  
⸻  
  
**6. Offline Sync Strategy (Append-Only Event Log)**  
  
**Event Types**  
	•	NOTE_CREATED  
	•	FIELD_UPDATED  
	•	INTERVENTION_ADDED  
	•	ATTACHMENT_ADDED  
	•	NOTE_SIGNED  
	•	ADDENDUM_ADDED  
  
**Example Event**  
  
```
{
  "type": "INTERVENTION_ADDED",
  
```
```
"noteId": "note_01",

```
```
  "at": "2026-01-20T10:14:00Z",
  
```
```
"actorId": "clin_88",

```
```
  "payload": { "type": "oxygen", "details": "NRB 15 L/min" }
}

```
  
**Conflict Resolution Rules**  
	1.	Signed notes are immutable  
	2.	Draft fields: last-writer-wins per field  
	3.	Arrays: merge by ID, never silently delete  
	4.	Conflicts resolved by user with new event  
  
⸻  
  
**7. Signing, Corrections, and Addenda**  
  
**Signing**  
	•	Locks note  
	•	Creates NOTE_SIGNED event  
	•	Prevents overwriting  
  
**Addendum Model**  
  
```
{
  "type": "ADDENDUM_ADDED",
  
```
```
"payload": {

```
```
    "correctionOf": "/objective/vitals/0/spo2",
    "text": "SpO2 was 82%, not 84%",
    "at": "2026-01-20T12:05:00Z",
    "actorId": "clin_88"
  }
}

```
  
  
⸻  
  
**8. UI Flow for Field Use**  
  
**Home**  
	•	New note  
	•	Continue drafts  
	•	Quick SBAR  
  
**New Note Flow**  
	1.	Triage + vitals  
	2.	Chief complaint + mechanism  
	3.	Focused exam  
	4.	Interventions (big action buttons)  
	5.	Disposition + SBAR  
	6.	Sign  
  
Principles:  
	•	Autosave always  
	•	Unknown allowed  
	•	One-screen critical actions  
  
⸻  
  
**9. Security in Scarce-Resource Settings**  
	•	Strong local encryption  
	•	App lock + biometrics / PIN  
	•	Panic lock button  
	•	Minimal identifiable data  
	•	Remote wipe (if MDM available)  
  
⸻  
  
**10. Optional Interoperability (When Connected)**  
	•	Export as PDF for transport  
	•	Export JSON for local systems  
	•	Optional FHIR Document:  
	•	Composition (note)  
	•	Observations (vitals)  
	•	Conditions (problems)  
	•	CarePlan (plan)  
	•	Provenance (audit)  
  
⸻  
  
**11. Summary**  
  
This architecture provides:  
	•	Clinically valid documentation  
	•	Speed in emergencies  
	•	Legal defensibility  
	•	Offline resilience  
	•	Interoperability when possible  
  
It supports SOAP, APSO, POMR, and SBAR from a single unified data model, optimized for harsh field environments.  
