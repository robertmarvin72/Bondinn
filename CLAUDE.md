# Bóndinn - Claude Instructions

## Project Overview

Bóndinn is an Icelandic farming management game built with Godot 4 and GDScript.

The game focuses on realistic Icelandic agriculture and farm management.

Core activities include:

* Hay production
* Sheep farming
* Dairy farming
* Horse breeding and training
* Fencing
* Fertilizing fields
* Machinery maintenance
* Farm finances
* Seasonal events (e.g. réttir)
* Weather-driven decision making

The game is a management/simulation game inspired by:

* Farming Simulator (management only)
* Stardew Valley (simplicity)
* Two Point games
* Cities Skylines (simulation depth)

## Visual Style

* Low poly
* Stylized graphics
* Earth tones
* Icelandic landscape
* Clean and readable UI

## Technology

* Engine: Godot 4
* Language: GDScript
* Main scene: `world.tscn`

## Current Architecture

### Scripts

* `world.gd`
* `field.gd`
* `weather.gd`

### UI

Current UI hierarchy:

UI
└── FieldPanel
└── FieldInfo

FieldInfo displays information about the selected field.

## Field System

Each field contains:

* `field_name`
* `grass_level`
* `fertility`
* `harvested`

Example fields:

* Heimatún
* Mýrin
* Hólar
* Nyrðra tún
* Suðurtún

Fields are clickable.

Clicking a field should update the UI.

## Weather System

Weather affects:

* Hay quality
* Grass growth
* Animal comfort
* Farm profitability

Weather types:

* SUNNY
* RAIN
* WIND
* STORM
* SNOW

## Gameplay Loop

Weather → Fields → Hay → Animals → Income → Farm Growth

## Coding Rules

IMPORTANT:

* Make the smallest safe change possible.
* Modify existing code before creating new systems.
* Explain the root cause before changing code.
* Avoid unnecessary abstractions.
* Avoid duplicate systems.
* Use Godot 4 best practices.
* Use GDScript only.
* Keep code simple and maintainable.
* Prefer exported variables over hardcoded values.

## AI Workflow

When debugging:

1. Diagnose root cause.
2. Explain findings.
3. Propose minimal fix.
4. Show code diff.
5. Wait for approval before large refactors.

Never redesign the architecture without explicit approval.

## Current Development Priorities

1. Field selection UI
2. Harvest system
3. Weather system
4. Economy system
5. Animals
6. Machinery
7. Seasons

## Long-Term Vision

Create the definitive Icelandic farming management game.
