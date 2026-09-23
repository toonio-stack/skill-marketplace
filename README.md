# skill-marketplace

Marketplace de **plugins Claude Code** pour toonio-stack. Les skills réutilisables
vivent ici sous forme de plugins, hors des dépôts cibles auxquels ils
s'appliquent. Chaque machine récupère le même comportement avec une seule
commande `/plugin install`.

Nom du marketplace : `toonio-skills`. Catalogue : `.claude-plugin/marketplace.json`.

| Plugin | Rôle |
|--------|------|
| `create-agent` | Concevoir et générer un package d'agent IA portable selon le standard The Boss (manifest, instructions, skills, tools, adapters, tests). À utiliser pour créer ou structurer un nouvel agent. |

## Installation (une fois, par machine)

Dans une session Claude Code :

```
/plugin marketplace add toonio-stack/skill-marketplace
/plugin install create-agent@toonio-skills
```

Les plugins s'installent au **scope utilisateur** (`~/.claude/plugins/`). Rien
n'est ajouté aux dépôts de projet. Chaque skill porte sa propre garde de
périmètre dans sa `description` pour rester silencieux lorsqu'il ne s'applique
pas.

Ce dépôt est **public** : aucune authentification n'est nécessaire pour
l'installation. Si un rafraîchissement en arrière-plan échoue, un
`/plugin marketplace update toonio-skills` dans une session suffit.

## Recevoir les mises à jour

Les plugins installés sont **épinglés** au moment de l'installation. Un merge
sur `main` seul ne change pas une installation locale. Une modification atteint
les installations lorsque le champ `version` de
`.claude-plugin/marketplace.json` est incrémenté (c'est l'acte de release) :

- Avec la mise à jour automatique en arrière-plan (activée par défaut), la
  nouvelle version est prise au prochain démarrage de session.
- Pour forcer immédiatement : `claude plugin update create-agent@toonio-skills`
- Pour rafraîchir seulement le catalogue : `/plugin marketplace update toonio-skills`

## Publier un changement

1. Créer une branche, modifier le skill ou le plugin, ouvrir une PR vers `main`.
2. **Dans la même PR**, incrémenter `version` dans **les deux** fichiers
   `plugins/<plugin>/.claude-plugin/plugin.json` et l'entrée du plugin dans
   `.claude-plugin/marketplace.json`. Sans bump de version, le merge n'est pas
   une release. `scripts/check.sh` échoue si les deux versions divergent.
3. Optionnel : tagger la release avec `claude plugin tag plugins/<plugin>`
   (crée `<plugin>--v<version>` et vérifie que les deux manifests concordent).
4. Optionnel, pour une reproductibilité stricte : après le merge, fixer le
   champ `sha` de l'entrée sur le commit de merge dans une PR de suivi. Avec
   un pin `sha`, même un force-push sur `main` ne déplace pas les versions
   installées.

## Développement local (itérer sans toucher l'installation)

Charger la copie de travail d'un plugin directement. L'installation marketplace
reste intacte pour cette session :

```bash
claude --plugin-dir /chemin/vers/skill-marketplace/plugins/create-agent
```

- La copie locale prend le pas sur la version marketplace installée pour cette
  session.
- Après une édition de `SKILL.md` en cours de session, lancer `/reload-plugins`
  pour prendre le changement en compte.
- Pour tester le fichier marketplace lui-même :
  `/plugin marketplace add ./skill-marketplace`
  (les marketplaces locaux ne se mettent pas à jour tout seuls ; rafraîchir
  avec `/plugin marketplace update toonio-skills`).

## Ajouter un skill / plugin

1. Copier le modèle :

   ```bash
   cp -r templates/plugin plugins/<plugin-name>
   mv plugins/<plugin-name>/skills/skill-name plugins/<plugin-name>/skills/<skill-name>
   ```

2. Éditer `plugins/<plugin-name>/.claude-plugin/plugin.json` : `name`,
   `description`, conserver `version: 0.1.0`.
3. Éditer `plugins/<plugin-name>/skills/<skill-name>/SKILL.md`. Le frontmatter
   contient `name` + `description`. La description pilote le déclenchement
   automatique, donc elle doit :
   - dire ce que fait le skill,
   - lister les phrases qui doivent le déclencher,
   - nommer le dépôt ou le contexte auquel il s'applique et demander à l'agent
     de rester silencieux ailleurs (les plugins au scope utilisateur sont actifs
     dans chaque dépôt ouvert).

   Mettre la description entre guillemets ou en scalaire bloc (`>-`) si elle
   contient un deux-points.
4. Ajouter l'entrée du plugin dans `.claude-plugin/marketplace.json` :

   ```json
   {
     "name": "<plugin-name>",
     "description": "Même texte que plugin.json",
     "author": { "name": "toonio-stack" },
     "category": "workflow",
     "version": "0.1.0",
     "source": {
       "source": "git-subdir",
       "url": "https://github.com/toonio-stack/skill-marketplace.git",
       "path": "plugins/<plugin-name>",
       "ref": "main"
     }
   }
   ```

5. Ajouter une ligne au tableau des plugins en tête de ce README.
6. Lancer `scripts/check.sh`, puis ouvrir une PR vers `main`.

Un plugin peut aussi embarquer `commands/`, `agents/` et `hooks/` à côté de
`skills/`. Voir la [référence des plugins](https://code.claude.com/docs/en/plugins-reference).

## Arborescence

```
.claude-plugin/marketplace.json     ← catalogue du marketplace (les versions vivent ici)
plugins/
  create-agent/
    .claude-plugin/plugin.json      ← manifeste du plugin
    skills/create-agent/SKILL.md    ← le skill
    skills/create-agent/examples/   ← exemples du skill
templates/plugin/                   ← copier ceci pour démarrer un nouveau plugin
scripts/check.sh                    ← valide les manifests et la cohérence des versions
LICENSE                             ← MIT
```

## Licence

MIT. Voir [LICENSE](LICENSE).

## Liens

- [Documentation Claude Code — plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Documentation Claude Code — référence des plugins](https://code.claude.com/docs/en/plugins-reference)
- [Documentation Claude Code — skills](https://code.claude.com/docs/en/skills)
- Modèle de structure : [joel/skill-marketplace](https://github.com/joel/skill-marketplace)
