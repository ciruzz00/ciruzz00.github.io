#!/bin/bash

# Convert .MD to .HTML
for file in posts/*.md; do
    output_file="public/posts/$(basename "$file" .md).html"
    pandoc "$file" -o "$output_file" --standalone --no-highlight --to=html5 --css="../css/style-post.css"
   
done
sed -i '/<link rel="stylesheet" href="\.\.\/css\/style-post\.css" \/>/a \
<link rel="icon" type="image/png" href="../img/favicon.ico">' $output_file

# Add files to blog.html
new_posts=$(ls public/posts/*.html)

# Create links for new posts
links=""
for post in $new_posts; do
    post_name=$(basename "$post" .html)
    links="$links<li><a href='posts/$post_name.html'>$post_name</a></li>"
done

# Insert new posts between <ul>...</ul> in blog.html
sed -i '/<ul>/,/<\/ul>/c\<ul>\n'"$links"'\n</ul>' public/blog.html

