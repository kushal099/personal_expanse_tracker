# AI Development Contract

This document defines strict development rules for all future AI-assisted coding in this Flutter project. It is intended to protect the current architecture, design quality, data model, and user experience while allowing careful incremental improvement.

## 1. Project Overview

This project is a Flutter fintech expense tracker with:

- Desktop and mobile support.
- Hive-based local persistence.
- Riverpod state management.
- Modular clean architecture.
- A polished dark fintech UI direction.
- Responsive layouts for phone, tablet, desktop, and wide desktop surfaces.

Future development must treat the existing implementation as the source of truth unless the user explicitly requests a larger redesign.

## 2. Non-Negotiable Rules

- NEVER overwrite polished implementations.
- ALWAYS review existing files before editing related behavior.
- Apply incremental, scoped changes only.
- Preserve the existing architecture.
- Preserve responsive behavior across mobile and desktop.
- Preserve Hive persistence.
- Preserve Riverpod reactivity.
- Preserve the current design system.
- Do not replace working systems with speculative rewrites.
- Do not remove existing functionality unless the user explicitly asks for it.

## 3. Architecture Rules

- Prefer reusable widgets over repeated UI code.
- Keep providers modular and feature-scoped.
- Avoid giant files.
- Avoid duplicated logic.
- Do not hardcode colors in feature widgets; use the theme and design system.
- Keep business logic out of UI widgets.
- Keep data access behind providers and services.
- Maintain clear feature boundaries under `screens/`, `providers/`, `services/`, `models/`, `widgets/`, `theme/`, and `core/`.

## 4. Flutter Rules

- `flutter analyze` must pass before work is considered complete.
- Avoid layout overflows on all supported screen sizes.
- Mobile and desktop compatibility is required for user-facing changes.
- Support dark theme only for now.
- Use `const` constructors where possible.
- Use Material and Flutter layout primitives consistently with the existing app.
- Validate scrolling, keyboard behavior, and constrained layouts for form-heavy screens.

## 5. State Management Rules

- Reactive updates are required everywhere user-visible state changes.
- Avoid manual refresh patterns when provider-driven reactivity can solve the problem.
- Prefer computed providers for derived values.
- Preserve provider naming consistency.
- Keep provider state typed and domain-specific.
- Avoid `dynamic` for app domain state unless there is no reasonable alternative.
- Do not duplicate source-of-truth state across unrelated providers.

## 6. Persistence Rules

- Hive is the source of truth for local expense and receivable data.
- Preserve backward compatibility with existing Hive boxes and adapters.
- Avoid destructive schema changes.
- Never change Hive type IDs casually.
- Add migrations or compatibility handling when model persistence changes are required.
- Keep persistence operations centralized in storage services and providers.

## 7. UI/UX Rules

- Maintain the premium fintech look.
- Use smooth, purposeful animations only.
- Provide proper empty states.
- Use responsive spacing and sizing.
- Ensure forms are keyboard-safe on mobile.
- Avoid visual regressions in dark mode.
- Preserve readability, hierarchy, and tap target quality.
- Keep interaction feedback clear for create, update, delete, undo, and error states.

## 8. Coding Standards

- Use clear, consistent naming.
- Keep widgets small and focused.
- Add comments only where they clarify non-obvious decisions.
- Keep imports clean and minimal.
- Remove dead code.
- Avoid broad formatting churn.
- Follow existing file organization and local conventions.
- Prefer simple, maintainable code over clever abstractions.

## 9. Agent Workflow

Before making changes, every AI coding agent must:

- Inspect the existing implementation.
- Understand nearby providers, widgets, models, and services.
- Preserve stable systems.
- Avoid broad rewrites.
- Make small, incremental edits.
- Validate changes incrementally.
- Run relevant checks whenever the local toolchain allows it.
- Report any blocked validation clearly.

When uncertain, prefer the smallest change that respects the existing architecture and user experience.
