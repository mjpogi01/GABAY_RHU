# GABAY

**Care for your little one** — An offline-first Flutter mobile app for parents and caregivers of children aged 0–2 years. Developed as a research and public health intervention tool in coordination with Barangay Health Workers (BHWs) and Rural Health Units (RHUs).

## Features

- **50 structured learning modules** covering newborn care, nutrition, responsive caregiving, safety, development, and caregiver well-being
- **Adaptive learning** — Pre-test identifies knowledge gaps; only relevant modules are assigned
- **Post-test** — Triggered 2 months (±1 week) after module completion; measures knowledge improvement
- **Offline-first** — SQLite local storage, works with intermittent or no internet
- **Digital certificate** — Generated upon meeting benchmark (80% post-test score)
- **Philippine Data Privacy Act (RA 10173) compliant** — Anonymized IDs for research, minimal data collection

## Project Structure

```
lib/
├── core/           # Constants, theme, routes
├── data/           # Seed data (modules, questions)
├── models/         # User, Child, Module, Question, Assessment, Progress
├── providers/      # App-wide state (Provider)
├── repositories/   # Data access (modules, assessments, progress)
├── screens/        # Auth, dashboard, pre-test, modules, post-test, certificate
├── services/       # Database, auth, adaptive logic, certificate, sync
└── main.dart
```

## Setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.5+)
- Android Studio / Xcode for emulators

### Install

1. Clone and enter the project:
   ```bash
   cd c:\Gabay
   ```

2. Add platform folders (if missing):
   ```bash
   flutter create . --org com.gabay --project-name gabay --platforms android,ios
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run:
   ```bash
   flutter run
   ```

## Expanding Content

- **Modules**: Edit `lib/data/seed_data.dart` or load from JSON assets. Add to `_getSampleModules()`.
- **Questions**: Add pre-test and post-test questions with `pairedId` linking same-intent pairs.
- **Domains**: Use `AppConstants.knowledgeDomains` — add new domains as needed.

## Adaptive Logic

1. **Pre-test** → Domain scores calculated
2. **Gap detection** → Domains below 70% threshold
3. **Module assignment** → Modules in those domains are required
4. **Post-test window** → 54–68 days after pre-test
5. **Certificate** → 80%+ post-test score

## Data Export

Analytics and research data (scores, engagement, completion) can be exported via the Excel package for evaluation. Implement export in a separate admin/research screen.

## License

Research and public health use. Contact project coordinators for licensing.
