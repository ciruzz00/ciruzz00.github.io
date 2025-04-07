---
title: Come ho creato il blog
---

<div class="content">

## l'idea

Volevo un modo semplice, leggero e completamente automatizzato per gestire un piccolo blog all’interno del mio sito portfolio statico ospitato su GitHub Pages.  
L’obiettivo era poter scrivere articoli in Markdown, caricarli in una cartella del repository e lasciare che tutto il resto – dalla conversione all’aggiornamento del sito – venisse gestito in automatico.

Così è nato un **mini-CMS statico** realizzato con:

- 📝 Markdown per scrivere i post
- 🔁 Pandoc per convertirli in HTML
- ⚙️ Uno script Bash per aggiornare i file
- 🤖 GitHub Actions per automatizzare tutto
- 💻 HTML/CSS puri per semplicità e portabilità

---

## 🚀 Come funziona

Ogni volta che carico un file `.md` nella cartella `posts/` e faccio push sulla branch `main`, una GitHub Action:

1. Installa Pandoc
2. Converte tutti i `.md` in `.html` con uno stile CSS personalizzato
3. Aggiorna automaticamente l’indice degli articoli nella pagina `blog.html`
4. Fa commit e push dei cambiamenti
5. Pubblica il sito aggiornato sulla branch `gh-pages`, visibile come GitHub Page

Tutto questo avviene senza dover toccare manualmente i file HTML.

---

## 🗂️ Struttura del progetto

```
.
├── posts/              # Post in formato Markdown
├── public/             # HTML generato per i post
│   ├── blog.html       # Pagina con l’elenco dei post
│   └── posts/          # Articoli convertiti in HTML
├── css/
│   └── style-post.css  # Stile dei post
├── convert.sh          # Script Bash per conversione e aggiornamento
└── .github/
    └── workflows/
        └── deploy.yml    # GitHub Actions workflow
```

---

## 🔧 Il workflow GitHub Actions

Questo è il cuore dell’automazione: quando viene eseguito un push su `main`, parte una pipeline che si occupa di tutto.

```yaml
name: Convert MD to HTML and Update Blog and create Github Page

permissions:
  contents: write

on:
  push:
    branches:
      - main
   
jobs:
  convert:
    runs-on: ubuntu-latest

    steps:
      # Checkout del repository
      - name: Checkout repository
        uses: actions/checkout@v4

      # Installa Pandoc
      - name: Install Pandoc
        run: sudo apt-get install pandoc gawk

      - name: Set permissions for convert script
        run: chmod +x convert.sh 

      - name: Run convert script
        run: ./convert.sh
        
      # Esegui git pull prima del commit e push
      - name: Pull latest changes from remote
        run: |
          git pull origin main

      # Fai il commit e push dei cambiamenti
      - name: Commit changes
        run: |
          git config --global user.name "GitHub Actions"
          git config --global user.email "actions@github.com"
          git add public/
          git diff --staged --quiet || git commit -m "Aggiornato blog.html e post"
          git push || echo "No changes to push"
        continue-on-error: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      # Crea la GitHub Page (pubblica su gh-pages)
      - name: Create GitHub Pages
        run: |
          # Crea una directory temporanea
          mkdir -p /tmp/gh-pages
          
          # Copia solo i file dalla directory public/ nella directory temporanea
          cp -r public/* /tmp/gh-pages/
          
          # Crea un branch completamente nuovo
          git checkout --orphan gh-pages
          
          # Rimuovi tutti i file dall'area di staging
          git rm -rf --cached .
          
          # Rimuovi tutti i file dalla directory di lavoro
          rm -rf *
          
          # Copia i file dalla directory temporanea
          cp -r /tmp/gh-pages/* .
          
          # Aggiungi i file al branch
          git add .
          
          # Commit dei file
          git commit -m "Update GitHub Pages with new posts"
          
          # Push al branch gh-pages
          git push --force origin gh-pages
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 🖥️ Lo script `convert.sh`

Questo script converte i file Markdown in HTML con Pandoc, aggiunge il CSS e aggiorna automaticamente l’indice degli articoli.

```bash
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
```

---

## ✨ Risultato

Ogni articolo viene pubblicato semplicemente facendo push del file Markdown.  
Non serve scrivere HTML, modificare l’indice o fare deploy manuale.  
Tutto viene gestito in automatico – ed è perfettamente integrato con GitHub Pages.

> È un’idea semplice, ma funziona bene per gestire un microblog personale o una sezione articoli in modo minimalista.

---

## Prossimi miglioramenti possibili

- Supporto per categorie o RSS
- Visualizzazione in ordine cronologico

[Blog](../blog/) [Home](../)
</div>