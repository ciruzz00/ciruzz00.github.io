#!/bin/bash

# Converte tutti i file .md in .html
for file in posts/*.md; do
    output_file="public/posts/$(basename "$file" .md).html"
    pandoc "$file" -o "$output_file" --standalone --no-highlight --to=html5 --css="../css/style-post.css"

    # Aggiunge favicon subito dopo il link al CSS
    sed -i '/<link rel="stylesheet" href="\.\.\/css\/style-post\.css" \/>/a \
<link rel="icon" type="image/png" href="../img/favicon.ico">' "$output_file"
done

# Genera elenco dei nuovi post con titoli
links=""
for file in posts/*.md; do
    post_basename=$(basename "$file" .md)
    
    # Estrae il titolo dal file markdown (prima riga che inizia con #)
    title=$(grep -m 1 "^# " "$file" | sed 's/^# //')
    
    # Se non trova un titolo, usa il nome del file
    if [ -z "$title" ]; then
        title="$post_basename"
    fi
    
    links+="<li><a href='posts/$post_basename.html'>$title</a></li>\n"
done

# Inserisce i link tra <ul> e </ul> in blog.html
temp_file=$(mktemp)
awk -v links="$links" '
  /<ul>/ { print; print links; next }
  /<\/ul>/ { print; next }
  { print }
' public/blog.html > "$temp_file" && mv "$temp_file" public/blog.html