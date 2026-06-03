---
name: code-and-design
description: 'Use for code and design work in the Lumina app: map a feature to the existing SwiftUI architecture, preserve the glassmorphic design system, and verify the implementation before shipping.'
argument-hint: 'Describe the feature, UI update, or implementation task to review and refine.'
user-invocable: true
disable-model-invocation: false
---

# Code and Design Workflow

## When to Use
- Add or refine app features in the Lumina SwiftUI project.
- Update visuals, components, or user flows while keeping the existing design language consistent.
- Review implementation quality before suggesting or applying changes.

## Goal
Create changes that are:
- aligned with the product story in the README and project journal,
- consistent with the existing design system in the Lumina app,
- grounded in the current SwiftUI + service-layer architecture.

## Procedure
1. Start with context
   - Read the project overview in [README.md](../../../README.md) to confirm the product goals.
   - Identify whether the task affects app flow, design system, services, or hardware integration.

2. Map the work to the right layer
   - UI and screens: inspect files under Source 2/Lumina/Lumina/Features.
   - Reusable visuals: inspect Source 2/Lumina/Lumina/DesignSystem.
   - App state and models: inspect Source 2/Lumina/Lumina/Core.
   - BLE/HomeKit integration: inspect Source 2/Lumina/Lumina/Core/Services.

3. Preserve design intent
   - Keep the glassmorphic dark theme, neon accents, and premium lamp-preview feel.
   - Reuse existing components such as GlassCard, NeonButton, GlassSlider, and ColorWheelPicker before creating new ones.
   - Avoid visual drift from the established Lumina theme.

4. Implement with architecture in mind
   - Keep screen logic in the feature layer.
   - Keep shared models and repositories in Core.
   - Keep connectivity logic in the service layer.
   - Prefer incremental, readable changes over broad rewrites.

5. Validate the result
   - Check that the change matches the current feature flow and state handling.
   - Confirm the UI still fits the existing design language.
   - If possible, verify the project still builds or test targets remain intact.

## Quality Checklist
- The update supports the app’s existing user journey.
- The design system is reused rather than duplicated.
- The implementation follows the existing folder structure and SwiftUI patterns.
- The result is understandable, maintainable, and consistent with the Lumina brand.

## Useful Starting Points
- [README.md](../../../README.md)
- Source 2/Lumina/Lumina/DesignSystem
- Source 2/Lumina/Lumina/Features
- Source 2/Lumina/Lumina/Core
