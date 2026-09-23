#!/usr/bin/env bash
# Validate the marketplace catalog and every plugin, and make sure each
# plugin's version matches its catalog entry. Run before opening a PR.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required (install jq and re-run)." >&2
  exit 1
fi

fail=0
catalog=.claude-plugin/marketplace.json

echo "== marketplace catalog"
if [ ! -f "$catalog" ]; then
  echo "   MISSING $catalog"
  echo
  echo "FAILED"
  exit 1
fi

if ! jq empty "$catalog" >/dev/null 2>&1; then
  echo "   INVALID JSON: $catalog"
  echo
  echo "FAILED"
  exit 1
fi

for field in '$schema' name owner metadata plugins; do
  if ! jq -e --arg f "$field" 'has($f)' "$catalog" >/dev/null; then
    echo "   MISSING required field: $field"
    fail=1
  fi
done

if ! jq -e '.name | type == "string" and length > 0' "$catalog" >/dev/null; then
  echo "   INVALID field: name"
  fail=1
fi

if ! jq -e '.owner.name | type == "string" and length > 0' "$catalog" >/dev/null; then
  echo "   MISSING required field: owner.name"
  fail=1
fi

for field in description version pluginRoot; do
  if ! jq -e --arg f "$field" '.metadata | has($f) and (.[$f] | type == "string" and length > 0)' "$catalog" >/dev/null; then
    echo "   MISSING required field: metadata.$field"
    fail=1
  fi
done

if ! jq -e '.plugins | type == "array" and length > 0' "$catalog" >/dev/null; then
  echo "   plugins must be a non-empty array"
  fail=1
fi

while IFS= read -r n; do
  [ -n "$n" ] || continue
  for field in description version category; do
    val=$(jq -r --arg n "$n" --arg f "$field" '.plugins[] | select(.name == $n) | .[$f] // empty' "$catalog")
    if [ -z "$val" ] || [ "$val" = "null" ]; then
      echo "   catalog entry '$n' missing $field"
      fail=1
    fi
  done
  source_kind=$(jq -r --arg n "$n" '.plugins[] | select(.name == $n) | .source.source // empty' "$catalog")
  source_path=$(jq -r --arg n "$n" '.plugins[] | select(.name == $n) | .source.path // empty' "$catalog")
  source_url=$(jq -r --arg n "$n" '.plugins[] | select(.name == $n) | .source.url // empty' "$catalog")
  source_ref=$(jq -r --arg n "$n" '.plugins[] | select(.name == $n) | .source.ref // empty' "$catalog")
  if [ -z "$source_kind" ] || [ "$source_kind" = "null" ]; then
    echo "   catalog entry '$n' missing source.source"
    fail=1
  fi
  if [ -z "$source_path" ] || [ "$source_path" = "null" ]; then
    echo "   catalog entry '$n' missing source.path"
    fail=1
  elif [ "$source_path" != "plugins/$n" ]; then
    echo "   PATH MISMATCH: catalog source.path=$source_path expected plugins/$n"
    fail=1
  fi
  if [ -z "$source_url" ] || [ "$source_url" = "null" ]; then
    echo "   catalog entry '$n' missing source.url"
    fail=1
  fi
  if [ -z "$source_ref" ] || [ "$source_ref" = "null" ]; then
    echo "   catalog entry '$n' missing source.ref"
    fail=1
  fi
done < <(jq -r '.plugins[].name' "$catalog")

if command -v claude >/dev/null 2>&1; then
  claude plugin validate "$catalog" || fail=1
else
  echo "   note: claude CLI not available; skipping 'claude plugin validate' on catalog"
fi

shopt -s nullglob
for dir in plugins/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  manifest="$dir.claude-plugin/plugin.json"
  echo "== plugin: $name"
  if [ ! -f "$manifest" ]; then
    echo "   MISSING $manifest"
    fail=1
    continue
  fi
  if ! jq empty "$manifest" >/dev/null 2>&1; then
    echo "   INVALID JSON: $manifest"
    fail=1
    continue
  fi

  for field in name description version; do
    if ! jq -e --arg f "$field" 'has($f) and (.[$f] | type == "string" and length > 0)' "$manifest" >/dev/null; then
      echo "   plugin.json missing required field: $field"
      fail=1
    fi
  done

  skill_count=0
  for skill in "$dir"skills/*/SKILL.md; do
    if [ -f "$skill" ]; then
      skill_count=$((skill_count + 1))
    fi
  done
  if [ "$skill_count" -eq 0 ]; then
    echo "   MISSING skills/*/SKILL.md"
    fail=1
  else
    echo "   skills: $skill_count SKILL.md"
  fi

  if command -v claude >/dev/null 2>&1; then
    claude plugin validate "$dir" || fail=1
  else
    echo "   note: claude CLI not available; skipping 'claude plugin validate'"
  fi

  plugin_version=$(jq -r '.version // empty' "$manifest")
  catalog_version=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .version' "$catalog")
  catalog_path=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .source.path' "$catalog")

  if [ -z "$catalog_version" ] || [ "$catalog_version" = "null" ]; then
    echo "   NOT IN CATALOG: add an entry for '$name' to $catalog"
    fail=1
  elif [ "$plugin_version" != "$catalog_version" ]; then
    echo "   VERSION MISMATCH: plugin.json=$plugin_version catalog=$catalog_version"
    fail=1
  else
    echo "   version $plugin_version OK"
  fi
  if [ -n "$catalog_version" ] && [ "$catalog_version" != "null" ] && [ "$catalog_path" != "plugins/$name" ]; then
    echo "   PATH MISMATCH: catalog source.path=$catalog_path expected plugins/$name"
    fail=1
  fi
done

echo "== catalog entries without a plugin directory"
for n in $(jq -r '.plugins[].name' "$catalog"); do
  [ -d "plugins/$n" ] || { echo "   '$n' listed but plugins/$n does not exist"; fail=1; }
done

if [ "$fail" -ne 0 ]; then
  echo
  echo "FAILED"
  exit 1
fi
echo
echo "All good."
