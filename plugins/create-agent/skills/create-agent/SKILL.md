---
name: create-agent
description: >-
  Concevoir, structurer ou générer un package d'agent IA portable selon le
  standard The Boss (manifest, instructions, skills, tools, adapters, tests).
  Déclencheurs : "créer un agent", "nouveau bot", "packager un agent",
  "create-agent", "standard The Boss". Skill générique de conception d'agents ;
  rester silencieux pour une tâche métier ponctuelle qui n'appelle pas un nouvel agent.
---

# create-agent

## Objectif

Concevoir et matérialiser un package d'agent portable complet à partir d'un besoin utilisateur, en suivant le cycle obligatoire et la structure standard The Boss.

## Quand utiliser

- Demande explicite de créer un nouvel agent / bot.
- Besoin récurrent qui justifie un agent spécialisé plutôt qu'une skill isolée.
- Découpage d'un agent trop large en agent dédié.
- Refonte d'un agent existant en package portable.

## Quand ne pas utiliser

- Tâche métier ponctuelle → handoff vers un exécuteur existant.
- Simple ajout d'une skill à un agent existant.
- Refactor d'un composant d'un package déjà là.
- Besoin trop vague sans critères de succès → clarifier d'abord.

## Principe

Portabilité maximale. Le cœur de l'agent ne dépend d'aucune plateforme IA. Les particularités plateforme vont dans `adapters/`. `provider` et `model` restent `null` dans le cœur.

## Structure cible (créer seulement ce qui est utile)

```text
agent-name/
├── manifest.yaml
├── agent.yaml
├── instructions.md
├── context.md
├── capabilities/
├── skills/
├── tools/
├── knowledge/
├── workflows/
├── schemas/
├── state/ tasks/ decisions/ sessions/ approvals/ handoffs/
├── tests/
│   ├── validation.yaml
│   └── portability.yaml
└── adapters/
```

Niveaux :

- Simple : manifest, agent.yaml, instructions.md, context.md
- Intermédiaire : + skills, knowledge, tools, workflows, schemas, tests
- Complexe : + state, tasks, decisions, approvals, handoffs, adapters

## Cycle obligatoire

1. Comprendre le besoin
2. Définir une responsabilité claire ; scinder si trop large
3. Identifier skills (réutiliser avant de créer)
4. Identifier tools comme contrats abstraits
5. Séparer knowledge du comportement
6. Définir workflows
7. Définir schémas / contrats I/O
8. Permissions minimum + approvals humaines
9. Générer l'arborescence utile uniquement
10. Vérifier la portabilité

Puis : répondre en 12 sections ; préparer un handoff si une exécution métier est requise.

## Format de réponse (12 sections)

1. Objectif
2. Responsabilités
3. Hors périmètre
4. Architecture
5. Skills
6. Tools
7. Knowledge
8. Workflows
9. Permissions et validations
10. Fichiers
11. Tests
12. Portabilité

## Interdits

- Secrets dans le package
- Permissions `read_all` / `write_all` / `admin` par défaut
- Connaissance indispensable uniquement dans la mémoire runtime
- Délégation floue (handoffs formalisés)
- Hardcoder provider/model dans le cœur

## Priorités en conflit

Sécurité et contrôle humain → exactitude → besoin utilisateur → séparation des responsabilités → portabilité → réutilisabilité → simplicité → maintenabilité → performance → sophistication.

## Entrées / sorties

**Entrées :** `requirement` (object), `package_root` (string), `reuse_search` (bool, défaut true), `locale` (défaut fr-FR).

**Sorties :** `design`, `package_tree`, `validation_report`, `open_approvals`, `response_12_sections`.

## Validations humaines

Approval si production, permissions élevées, ou hypothèses bloquantes avant écriture massive.

## Erreurs

`ambiguous_requirement`, `id_collision`, `validation_failed`, `secret_detected`, `reuse_preferred`.

## Exemples

**A) invoice-triage :** package avec tools abstraits `document.read`, `classifier.label` + handoff exécuteur.

**B) « Envoie 500 emails » :** ne pas exécuter ; proposer handoff `email-campaign-executor` + approval.
