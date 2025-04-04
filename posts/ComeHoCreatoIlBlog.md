---
title: come ho creato il blog
---

<div class="content">

# l'idea

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
    branches: [main]

jobs:
  convert:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Pandoc
        run: sudo apt-get install pandoc
      - name: Convert and update posts
        run: chmod +x convert.sh && ./convert.sh
      - name: Pull latest changes
        run: git pull origin main
      - name: Commit changes
        run: |
          git config --global user.name "GitHub Actions"
          git config --global user.email "actions@github.com"
          git add public/blog.html
          git commit -m "Aggiornato blog.html con nuovi post"
          git push
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Deploy to GitHub Pages
        run: |
          git checkout -B gh-pages
          cp -r public/* .
          git add .
          git commit -m "Update GitHub Pages with new posts"
          git push --force origin gh-pages
```

---

## 🖥️ Lo script `convert.sh`

Questo script converte i file Markdown in HTML con Pandoc, aggiunge il CSS e aggiorna automaticamente l’indice degli articoli.

```bash
#!/bin/bash

# Converte ogni file .md in .html
for file in posts/*.md; do
    output_file="public/posts/$(basename "$file" .md).html"
    pandoc "$file" -o "$output_file" --standalone --no-highlight --to=html5 --css="../css/style-post.css"
done

# Aggiunge favicon
sed -i '/<link rel="stylesheet" href="\.\.\/css\/style-post\.css" \/>/a \
<link rel="icon" type="image/png" href="../img/favicon.ico">' $output_file

# Genera l'elenco dei post
links=""
for post in public/posts/*.html; do
    post_name=$(basename "$post" .html)
    links="$links<li><a href='posts/$post_name.html'>$post_name</a></li>"
done

# Sostituisce il contenuto tra <ul> e </ul> in blog.html con i nuovi link
sed -i '/<ul>/,/<\/ul>/c\<ul>\n'"$links"'\n</ul>' public/blog.html
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

</div>