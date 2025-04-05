#!/bin/bash

# Assicura che la directory esista
mkdir -p public/posts

# Converte tutti i file .md in .html
for file in posts/*.md; do
    # Verifica che ci siano file .md
    if [ ! -f "$file" ]; then
        echo "Nessun file markdown trovato in posts/"
        break
    fi
    
    # Crea la directory di output se non esiste
    output_file="public/posts/$(basename "$file" .md).html"
    mkdir -p "$(dirname "$output_file")"
    
    echo "Conversione di $file in $output_file"
    pandoc "$file" -o "$output_file" --standalone --no-highlight --to=html5 --css="../css/style-post.css"

    # Aggiunge favicon subito dopo il link al CSS
    sed -i '/<link rel="stylesheet" href="\.\.\/css\/style-post\.css" \/>/a \
<link rel="icon" type="image/png" href="../img/favicon.ico">' "$output_file"
done

# Verifica che il file blog.html esista
if [ ! -f "public/blog.html" ]; then
    echo "File public/blog.html non trovato!"
    exit 1
fi

# Genera elenco dei nuovi post con titoli
links=""
for file in posts/*.md; do
    # Verifica che ci siano file .md
    if [ ! -f "$file" ]; then
        echo "Nessun file markdown trovato in posts/"
        break
    fi
    
    post_basename=$(basename "$file" .md)
    
    # Estrae prima il titolo dal blocco YAML
    title=$(awk '
        /^---$/ { in_yaml = !in_yaml; next }
        in_yaml && /^title:/ { print substr($0, index($0,$2)); exit }
    ' "$file")
    
    # Se non trovato, cerca una riga che inizia con #
    if [ -z "$title" ]; then
        title=$(grep -m 1 "^#\+ " "$file" | sed 's/^#\+ //')
    fi

    # Se ancora vuoto, usa il nome del file
    if [ -z "$title" ]; then
        title="$post_basename"
    fi

    echo "Aggiunto link per $title ($post_basename.html)"
    links+="<li><a href='posts/$post_basename.html'>$title</a></li>\n"
done

# Inserisce i link tra <ul> e </ul> in blog.html
if [ -n "$links" ]; then
    echo "Aggiornamento di public/blog.html con i nuovi link"
    temp_file=$(mktemp)
    awk -v links="$links" '
      /<ul>/ { print; print links; next }
      /<\/ul>/ { print; next }
      { print }
    ' public/blog.html > "$temp_file" && mv "$temp_file" public/blog.html
    echo "Blog.html aggiornato con successo!"
else
    echo "Nessun link da aggiungere a blog.html"
fi
