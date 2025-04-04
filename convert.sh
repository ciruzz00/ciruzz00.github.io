#!/bin/bash

# Converte tutti i file .md in .html
for file in posts/*.md; do
    output_file="public/posts/$(basename "$file" .md).html"
    pandoc "$file" -o "$output_file" --standalone --no-highlight --to=html5 --css="../css/style-post.css"

    # Aggiunge favicon subito dopo il link al CSS
    sed -i '/<link rel="stylesheet" href="\.\.\/css\/style-post\.css" \/>/a \
<link rel="icon" type="image/png" href="../img/favicon.ico">' "$output_file"
done

# Genera elenco dei nuovi post
links=""
for post in public/posts/*.html; do
    post_name=$(basename "$post" .html)
    links+="<li><a href='posts/$post_name.html'>$post_name</a></li>\n"
done

# Inserisce i link tra <ul> e </ul> in blog.html
# Protezione dai caratteri speciali usando un file temporaneo
temp_file=$(mktemp)
awk -v links="$links" '
  /<ul>/ { print; print_links=1; next }
  /<\/ul>/ { print_links=0; print links; print; next }
  !print_links { print }
' public/blog.html > "$temp_file" && mv "$temp_file" public/blog.html
