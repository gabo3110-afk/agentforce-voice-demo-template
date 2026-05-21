#!/usr/bin/env bash
# Renames the "Brand" placeholder across the project to your customer's brand name.
#
# Usage:
#   ./scripts/rename-brand.sh "Toyota"
#   ./scripts/rename-brand.sh "Brand" "Toyota"   # explicit search/replace
#
# What gets replaced:
#   Brand     → <NewBrand>      (PascalCase: class names, custom objects, .agent vars)
#   brand     → <newbrand>      (lowercase: file paths, asset references)
#   <BRAND>   → <NEWBRAND>      (uppercase placeholder in comments/instructions)
#   <Brand>   → <NewBrand>      (placeholder in comments)
#   <brand>   → <newbrand>      (placeholder in URLs/emails)

set -euo pipefail

SEARCH="${1:-Brand}"
REPLACE="${2:-}"

if [[ -z "$REPLACE" ]]; then
    if [[ "$SEARCH" == "Brand" ]]; then
        echo "Usage: $0 <NewBrandPascalCase>"
        echo "       $0 Brand <NewBrandPascalCase>"
        exit 1
    fi
    REPLACE="$SEARCH"
    SEARCH="Brand"
fi

# Derive case variants from REPLACE (assumes PascalCase input)
LOWER=$(echo "$REPLACE" | tr '[:upper:]' '[:lower:]')
UPPER=$(echo "$REPLACE" | tr '[:lower:]' '[:upper:]')

SEARCH_LOWER=$(echo "$SEARCH" | tr '[:upper:]' '[:lower:]')
SEARCH_UPPER=$(echo "$SEARCH" | tr '[:lower:]' '[:upper:]')

echo "Renaming:"
echo "  $SEARCH       → $REPLACE"
echo "  $SEARCH_LOWER → $LOWER"
echo "  $SEARCH_UPPER → $UPPER"
echo "  <$SEARCH_UPPER>     → <$UPPER>"
echo "  <$SEARCH>     → <$REPLACE>"
echo "  <$SEARCH_LOWER>     → <$LOWER>"
echo ""
read -p "Proceed? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || exit 0

# Rename file/directory paths first (deepest first, so renames don't break parent paths)
find force-app -depth -name "*${SEARCH}*" | while read path; do
    new_path=$(echo "$path" | sed "s|${SEARCH}|${REPLACE}|g")
    mv "$path" "$new_path"
done

# Replace contents (find all text files, run sed)
find force-app scripts docs -type f \( -name "*.xml" -o -name "*.cls" -o -name "*.cls-meta.xml" \
    -o -name "*.agent" -o -name "*.flow-meta.xml" -o -name "*.bundle-meta.xml" \
    -o -name "*.permissionset-meta.xml" -o -name "*.object-meta.xml" -o -name "*.field-meta.xml" \
    -o -name "*.labels-meta.xml" -o -name "*.translation-meta.xml" \
    -o -name "*.apex" -o -name "*.md" -o -name "*.json" \) | while read f; do
    sed -i.bak \
        -e "s|<${SEARCH_UPPER}>|<${UPPER}>|g" \
        -e "s|<${SEARCH}>|<${REPLACE}>|g" \
        -e "s|<${SEARCH_LOWER}>|<${LOWER}>|g" \
        -e "s|${SEARCH_UPPER}|${UPPER}|g" \
        -e "s|${SEARCH}|${REPLACE}|g" \
        -e "s|${SEARCH_LOWER}|${LOWER}|g" \
        "$f"
    rm -f "${f}.bak"
done

echo "Done. Verify with: git diff"
