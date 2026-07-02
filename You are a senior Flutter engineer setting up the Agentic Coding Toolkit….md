You are a senior Flutter engineer setting up the Agentic Coding Toolkit (ACT)   
workflow structure for an existing Flutter project called FluentArc — an   
AI-powered accent and fluency coaching app for non-native English speakers.  
  
Your job is to analyse the current codebase and create the ACT scaffolding files   
with real, accurate content derived from what you find. Do NOT invent or assume   
architecture that isn't reflected in the code. Everything you write must be   
grounded in what actually exists in this repo.  
  
## STEP 1 — ANALYSE THE CODEBASE FIRST  
  
Before creating any file, read and understand:  
  
1. `pubspec.yaml` — list every dependency and dev dependency  
2. `lib/` folder structure — full tree, all folders and files  
3. `lib/main.dart` — app entry point, router setup, providers/BLoC setup  
4. Any existing BLoC, Cubit, or state management files  
5. Any existing service or repository layer files  
6. Any existing model/entity files  
7. `ios/` folder — check for any Swift files, native plugins, or Info.plist entries  
8. Any existing `README.md`  
  
Do not skim. Read the actual file contents where relevant. Your output quality   
depends entirely on the accuracy of what you extract here.  
  
## STEP 2 — CREATE THESE FILES  
  
After analysis, create each file below with content derived from your findings.  
  
### FILE 1: `CLAUDE.md`  
  
This is the session bootstrap file that Claude Code reads automatically at the   
start of every session. Keep it concise and accurate.  
  
Structure it exactly like this:  
## Project: FluentArc  
## What this project is  
[1–2 sentences: what FluentArc does and who it's for]  
## Flutter app location  
Repo root (pubspec.yaml at root)  
## Tech stack  
[List every package from pubspec.yaml with its version and one-line purpose]  
## Architecture  
[Describe the actual pattern you found: BLoC/Cubit/Provider/Riverpod, folder structure, layer separation — only what exists, not aspirational]  
## Folder structure  
[Paste the actual lib/ tree you found]  
## Key files to know  
[List 5–8 critical files with path and one-line description of what each does]  
## Native integrations  
[List any iOS/Android native code found. If none yet, write "None yet."]  
## AI service integrations  
[List any Gemini, Deepgram, ElevenLabs, Supabase or other AI/backend service references found in code or pubspec. If none yet, write "Planned: Gemini 2.5 Flash (scoring), Deepgram Nova-3 (transcription), ElevenLabs (voice playback), Supabase (auth + storage)"]  
## Critical rules  
* Never add packages without checking pubspec.yaml first  
* State management: [whatever you found — BLoC/Cubit/etc]  
* Navigation: [whatever router you found — go_router/auto_route/Navigator]  
* Always run flutter analyze before marking any task done  
* Always run flutter test before marking any task done  
## Current active plan  
None yet — see ai_specs/ when work begins  
  
### FILE 2: `ai_docs/architecture.md`  
  
This is the living technical architecture document. Future AI sessions load   
this to understand the system without reading all the code.  
  
Structure:  
## FluentArc — Architecture  
## System overview  
[Describe what FluentArc is architecturally: Flutter app + AI backend services. One paragraph.]  
## Core feature domains  
List these four domains (they are the planned product structure):  
1. Audio recording — capturing user speech  
2. AI scoring — pronunciation and fluency analysis  
3. Voice playback — reference audio and user replay  
4. User progression — streaks, scores, lesson history  
## State management  
[Document what you found. If BLoC: list known Blocs/Cubits. If nothing yet: write "Not yet implemented — BLoC + Clean Architecture planned"]  
## Navigation  
[Document the router you found. If nothing: write "Not yet implemented — go_router planned"]  
## Service layer  
[List any service classes found. If none: write "Not yet implemented."]  
## Data layer  
[List any model/entity/repository classes found. If none: write "Not yet implemented."]  
## AI services (planned integrations)  
**Gemini 2.5 Flash**  
* Role: pronunciation scoring and fluency feedback  
* Input: transcribed text + audio metadata  
* Output: score (0–100), feedback string, phoneme-level notes  
**Deepgram Nova-3**  
* Role: speech-to-text transcription  
* Input: recorded audio (WAV or M4A)  
* Output: transcript with word-level confidence scores  
**ElevenLabs**  
* Role: reference voice playback (native speaker audio)  
* Input: text phrase  
* Output: audio stream  
**Supabase**  
* Role: user auth, session storage, lesson history, audio file storage  
* Tables planned: users, sessions, lessons, recordings  
## Known constraints  
[List anything critical from pubspec, Info.plist, or code that constrains what can be done — e.g. min iOS version, permissions required, etc.]  
## What does NOT exist yet  
[Be honest. List any planned feature that has zero code yet.]  
  
### FILE 3: `ai_docs/solutions/README.md`  
  
Simple index file for the solutions folder.  
## ACT Solutions — FluentArc  
This folder contains reusable lessons captured by /act-workflow-compound after each significant implementation session.  
Each file documents:  
* Key decisions made and why  
* Patterns that worked in this codebase  
* Pitfalls and gotchas discovered  
* Platform-specific notes  
## Index  
(empty — will populate as sessions complete)  
## How to use  
When starting a new Claude Code session on a complex task, reference relevant solution docs in your prompt or CLAUDE.md to give the AI prior context.  
  
### FILE 4: `ai_specs/README.md`  
  
Index file for the specs folder.  
## ACT Specs — FluentArc  
This folder contains all feature specifications and implementation plans generated by the ACT workflow.  
## Naming convention  
* NNN-feature-name.md — your raw initial idea / prompt  
* NNN-feature-name-spec.md — generated by /act-workflow-spec  
* NNN-feature-name-plan.md — generated by /act-workflow-plan  
## Index  
(empty — will populate as features are specced)  
## Feature domains  
Features will be numbered in this order:  
* 001 — Audio recording pipeline  
* 002 — Deepgram transcription integration  
* 003 — Gemini scoring integration  
* 004 — ElevenLabs playback integration  
* 005 — Supabase auth + user sessions  
* 006 — Lesson progression and history  
  
### FILE 5: `ai_docs/known-gotchas.md`  
  
A place to pre-seed known issues before any sessions run.  
## FluentArc — Known Gotchas  
Pre-seeded before first ACT session. Update this file whenever a new gotcha is discovered during development.  
## Audio recording (iOS)  
* Requires NSMicrophoneUsageDescription in Info.plist  
* AVAudioSession must be configured before recording starts  
* Background audio requires UIBackgroundModes: audio in Info.plist  
* M4A format preferred for iOS; WAV for Deepgram compatibility — may need format conversion step  
## Deepgram  
* Nova-3 model requires model=nova-3 query param  
* Streaming vs file upload: for accent coaching, batch file upload is simpler to implement first  
* Word-level timestamps require punctuate=true&words=true params  
## Gemini 2.5 Flash  
* Multimodal input (audio + text) available but adds latency  
* For scoring: send transcript text + Deepgram confidence scores rather than raw audio — cheaper and faster  
* Rate limits: check current tier before designing retry logic  
## ElevenLabs  
* Streaming playback requires chunked HTTP response handling  
* Voice cloning not needed — use a standard voice ID  
* Audio format: MP3 stream works on iOS with AVPlayer  
## Supabase  
* Row Level Security (RLS) must be enabled on all tables  
* Auth tokens expire — implement refresh token logic early  
* Storage buckets for audio files: set to private, use signed URLs  
## Flutter general  
* flutter analyze must pass with zero errors before any commit  
* flutter test must pass before any commit  
* Do not add packages without explicit approval — check pubspec.yaml first  
* Always run on physical device for audio testing — simulator has no microphone  
## State management  
[You fill this in after analysing the codebase]  
## Known issues found in current codebase  
[You fill this in after analysing the codebase — list any lint errors, TODO comments, or incomplete implementations you found]  
  
## STEP 3 — FINAL REPORT  
  
After creating all files, give me a short report:  
  
1. **What you found** — actual packages, folder structure, existing code summary  
2. **What was accurate vs assumed** — flag anything you couldn't verify from the   
   code and had to write as "planned"  
3. **Gaps to fill manually** — anything in the files you left as a placeholder   
   that I need to complete  
4. **Suggested first spec** — based on what exists and what doesn't, recommend   
   which feature domain I should write `001-initial-prompt.md` for first  
  
## CONSTRAINTS  
  
- Do not hallucinate package names or versions — read pubspec.yaml exactly  
- Do not describe architecture that doesn't exist — mark it as "planned"  
- Do not create ai_specs/001-initial-prompt.md — that's my job  
- Create folders implicitly by creating files inside them  
- All markdown files should use plain headings and prose — no emoji, no   
  decorative formatting  
- Write for a developer audience — concise, accurate, no padding.  
