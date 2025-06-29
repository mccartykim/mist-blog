{ pkgs, lib, stdenv }:

let
  # Site configuration - customize these values
  config = {
    title = "kimb.dev";
    description = "The personal blog of Kimberly McCarty";
    author = "Kimberly McCarty";
    email = "kimb@kimb.dev";
    copyright = "Kimberly McCarty (CC BY 4.0)";
    generator = "Made with <a href=\"https://nixos.org\">Nix</a>";
    language = "en-US";
  };

  # Constants - extracted for easier customization and separation
  constants = {
    # Site URLs
    baseUrl = "https://kimb.dev";
    rssUrl = "https://kimb.dev/rss.xml";
    
    # Dialogue character names for RSS cleaning and CSS
    dialogueCharacters = [ "questioner" "author" "reader" ];
    
    # CSS class names
    cssClasses = {
      sidenote = "sidenote";
      note = "note";
      content = "content";
      dialogue = "dialogue";
    };
  };
  
  # Tag parsing function - parses comma-separated tags
  parseTags = tagString:
    if tagString == "" || tagString == null then []
    else 
      map (tag: lib.trim tag) (lib.splitString "," tagString);

  # Extract description from markdown content (first paragraph, max 200 chars)
  extractDescription = content:
    let
      # Remove markdown formatting and get first paragraph
      lines = lib.splitString "\n" content;
      nonEmptyLines = lib.filter (line: lib.trim line != "") lines;
      firstParagraph = if nonEmptyLines != [] then lib.head nonEmptyLines else "";
      # Strip basic markdown (**, *, [], etc.) and truncate
      cleaned = lib.replaceStrings ["**" "*" "[" "]" "#"] ["" "" "" "" ""] firstParagraph;
      truncated = if lib.stringLength cleaned > 200 
                  then lib.substring 0 197 cleaned + "..."
                  else cleaned;
    in truncated;

  # Clean HTML content for RSS feeds - strips complex formatting for readability
  # Removes sidenotes, dialogue boxes, and CSS classes, keeping only basic HTML
  # This ensures maximum compatibility with RSS readers
  cleanRssContent = htmlContent:
    let
      # Remove sidenotes entirely (they're supplementary content)
      removeSidenotes = content:
        builtins.replaceStrings 
          ["<span class=\"sidenote\">" "<span class=\"note\">" "</span>"]
          ["" "" " "]
          content;
      
      # Remove dialogue boxes entirely (convert to regular paragraphs)
      removeDialogue = content:
        builtins.replaceStrings
          ["<div class=\"dialogue questioner\">" "<div class=\"dialogue author\">" "<div class=\"dialogue reader\">" "</div>"]
          ["" "" "" " "]
          content;
      
      # Remove all class and id attributes for clean RSS
      stripAttributes = content:
        let
          # Remove common class attributes
          noClasses = builtins.replaceStrings 
            [" class=\"sidenote\"" " class=\"note\"" " class=\"dialogue questioner\"" " class=\"dialogue author\"" " class=\"dialogue reader\"" " class=\"content\""]
            ["" "" "" "" "" ""]
            content;
          # Remove id attributes  
          noIds = builtins.replaceStrings 
            [" id=\"sidenotes-and-margin-notes\"" " id=\"dialogue-boxes\"" " id=\"custom-characters\""]
            ["" "" ""]
            noClasses;
        in noIds;
      
      # Remove structural HTML tags, keeping only semantic ones
      # Keep: <strong>, <em>, <code>, <pre>, <blockquote>, <a>
      # Remove: <p>, <div>, <br>, <h1-h6>, <span>, <ul>, <ol>, <li>
      removeStructuralTags = content:
        let
          # First remove tags with common attributes
          withAttrs = builtins.replaceStrings
            ["<h2 id=\"section-title\">" "<h1 id=\"section-title\">" "<h3 id=\"section-title\">"]
            ["" "" ""]
            content;
          # Then remove basic tags
          basic = builtins.replaceStrings 
            ["<p>" "</p>" "<div>" "</div>" "<br>" "<br/>" "<br />" 
             "<h1>" "</h1>" "<h2>" "</h2>" "<h3>" "</h3>" "<h4>" "</h4>" "<h5>" "</h5>" "<h6>" "</h6>"
             "<ul>" "</ul>" "<ol>" "</ol>" "<li>" "</li>" "<span>" "</span>"]
            ["" " " "" " " "" "" "" 
             "" " " "" " " "" " " "" " " "" " " "" " "
             "" " " "" " " "" " " "" " "]
            withAttrs;
        in basic;
      
      # Apply cleaning steps
      step1 = removeSidenotes htmlContent;
      step2 = removeDialogue step1; 
      step3 = stripAttributes step2;
      step4 = removeStructuralTags step3;
    in step4;
      
  # Extract metadata and content from markdown frontmatter
  extractMeta = content: 
    let
      lines = lib.splitString "\n" content;
      # Find the second --- to end frontmatter
      findSecondDash = idx:
        if idx >= lib.length lines then idx
        else if lib.elemAt lines idx == "---" then idx
        else findSecondDash (idx + 1);
      
      secondDashIdx = findSecondDash 1;
      frontmatterLines = lib.take (secondDashIdx - 1) (lib.drop 1 lines);
      contentLines = lib.drop (secondDashIdx + 1) lines;
      markdown = lib.concatStringsSep "\n" contentLines;
      
      parseLine = line:
        if lib.hasInfix ":" line then
          let 
            parts = lib.splitString ":" line;
            key = lib.head parts;
            value = lib.removePrefix " " (lib.concatStringsSep ":" (lib.tail parts));
          in {
            inherit key;
            value = lib.removePrefix "'" (lib.removeSuffix "'" value);
          }
        else null;
      
      metaPairs = lib.filter (x: x != null) (map parseLine frontmatterLines);
      meta = lib.listToAttrs (map (pair: lib.nameValuePair pair.key pair.value) metaPairs);
    in {
      inherit meta markdown;
    };

  # CSS content (extracted from hugo-bearcub theme)
  css = builtins.readFile ./assets/style.css;

  # HTML templates
  baseTemplate = { title, content, description ? config.description, url ? "${constants.baseUrl}/", type ? "website" }: ''
    <!DOCTYPE html>
    <html lang="${config.language}">
    <head>
      <meta http-equiv="X-Clacks-Overhead" content="GNU Terry Pratchett" />
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>${if title != "" then "${title} | ${config.title}" else config.title}</title>
      <meta name="description" content="${description}">
      
      <!-- Open Graph / Facebook -->
      <meta property="og:type" content="${type}" />
      <meta property="og:url" content="${url}" />
      <meta property="og:title" content="${if title != "" then title else config.title}" />
      <meta property="og:description" content="${description}" />
      <meta property="og:site_name" content="${config.title}" />
      
      <!-- Twitter -->
      <meta name="twitter:card" content="summary" />
      <meta name="twitter:url" content="${url}" />
      <meta name="twitter:title" content="${if title != "" then title else config.title}" />
      <meta name="twitter:description" content="${description}" />
      
      <link rel="alternate" type="application/rss+xml" title="${config.title} RSS" href="/rss.xml" />
      <style>${css}</style>
    </head>
    <body>
      <header>
        <a class="skip-link" href="#main-content">Skip to main content</a>
        <a href="/" class="title"><h1>${config.title}</h1></a>
        <nav><a href="/">Home</a><a href="/blog/">Blog</a><a href="/tags/">Tags</a></nav>
      </header>
      <main id="main-content">
        ${content}
      </main>
      <footer>
        <small>
          ${config.copyright} | ${config.generator}
        </small>
      </footer>
    </body>
    </html>
  '';

  # Single post template
  postTemplate = { title, date, content, author ? "", tags ? [] }: ''
    <h1>${title}</h1>
    <p class="byline">
      <time datetime="${date}" pubdate>${date}</time>
      ${if author != "" then "· ${author}" else ""}
    </p>
    ${if tags != [] then ''
      <p class="post-tags">
        Tags: ${lib.concatStringsSep " " (map (tag: ''
          <a href="/tags/${tag}/" class="tag">${tag}</a>
        '') tags)}
      </p>
    '' else ""}
    <div class="content">
${content}
    </div>
  '';

  # Blog index template
  indexTemplate = posts: ''
    <div class="content">
      <ul class="blog-posts">
        ${lib.concatStringsSep "\n" (map (post: ''
          <li>
            <span>
              <i>
                <time datetime="${post.date}" pubdate>${post.date}</time>
              </i>
            </span>
            <a href="${post.url}">${post.title}</a>
          </li>
        '') posts)}
      </ul>
    </div>
  '';
  
  # Tag index template - shows all tags
  tagIndexTemplate = ''
    <content>
      <h1>Tags</h1>
      <div class="tag-cloud">
        ${lib.concatStringsSep " " (map (tag: ''
          <a href="/tags/${tag}/" class="tag tag-size-${toString (
            if tagCounts.${tag} >= 5 then "large"
            else if tagCounts.${tag} >= 3 then "medium"
            else "small"
          )}">${tag} (${toString tagCounts.${tag}})</a>
        '') (lib.sort (a: b: a < b) allTags))}
      </div>
    </content>
  '';
  
  # Single tag page template
  tagPageTemplate = tag: posts: ''
    <content>
      <h1>Tag: ${tag}</h1>
      <p>${toString (lib.length posts)} post${if lib.length posts == 1 then "" else "s"} tagged with "${tag}"</p>
      <ul class="blog-posts">
        ${lib.concatStringsSep "\n" (map (post: ''
          <li>
            <span>
              <i>
                <time datetime="${post.date}" pubdate>${post.date}</time>
              </i>
            </span>
            <a href="${post.url}">${post.title}</a>
          </li>
        '') posts)}
      </ul>
      <p><a href="/tags/">← All tags</a></p>
    </content>
  '';

  # Process a single markdown file
  processMarkdown = path: name:
    let
      content = builtins.readFile path;
      parsed = extractMeta content;
      draft = parsed.meta.draft or "false";
      tagString = parsed.meta.tags or "";
      tags = parseTags tagString;
      description = extractDescription parsed.markdown;
    in
    if draft == "true" then null
    else {
      inherit name tags description;
      title = parsed.meta.title or name;
      date = parsed.meta.date or "1970-01-01";
      author = parsed.meta.author or "";
      content = parsed.markdown;
      url = "/blog/${lib.removeSuffix ".md" name}/";
      fullUrl = "${constants.baseUrl}/blog/${lib.removeSuffix ".md" name}/";
    };

  # Get all blog posts
  blogDir = ./content/blog;
  blogFiles = builtins.attrNames (builtins.readDir blogDir);
  markdownFiles = builtins.filter (name: lib.hasSuffix ".md" name && name != "_index.md") blogFiles;
  
  allPosts = lib.filter (x: x != null) (map (name: processMarkdown (blogDir + "/${name}") name) markdownFiles);
  sortedPosts = lib.sort (a: b: a.date > b.date) allPosts;
  
  # Collect all unique tags and group posts by tag
  allTags = lib.unique (lib.flatten (map (post: post.tags) allPosts));
  postsByTag = lib.genAttrs allTags (tag:
    lib.filter (post: lib.elem tag post.tags) sortedPosts
  );
  
  # Count posts per tag for tag cloud
  tagCounts = lib.genAttrs allTags (tag:
    lib.length postsByTag.${tag}
  );

  # Process home page content
  homeContent = builtins.readFile ./content/_index.md;
  homeParsed = extractMeta homeContent;


  # Individual derivations for each component
  
  # Home page - create directly as a file with destination
  mainIndexPage = pkgs.runCommand "main-index" { buildInputs = [ pkgs.pandoc ]; } ''
    mkdir -p $out
    
    # Write markdown to file to avoid shell escaping issues
    cat > home_content.md << 'HOME_EOF'
${homeParsed.markdown}
HOME_EOF
    
    pandoc -f markdown -t html home_content.md > home_content.html
    HOME_HTML=$(cat home_content.html)
    
    cat > $out/index.html << EOF
${baseTemplate {
      title = "";
      content = "\$HOME_HTML";
    }}
EOF
  '';
  
  # Blog index page
  blogIndexPage = pkgs.runCommand "blog-index" {} ''
    mkdir -p $out/blog
    cat > $out/blog/index.html << 'EOF'
${baseTemplate {
      title = "Blog";
      content = indexTemplate sortedPosts;
    }}
EOF
  '';
  
  # Individual blog post pages
  postPages = map (post: 
    pkgs.runCommand "post-${post.name}" { buildInputs = [ pkgs.pandoc ]; } ''
      mkdir -p "$out/blog/${lib.removeSuffix ".md" post.name}"
      
      # Write content to file to avoid shell escaping issues
      cat > post_content.md << 'POST_EOF'
${post.content}
POST_EOF
      
      pandoc -f markdown -t html --highlight-style=tango post_content.md > post_content.html
      POST_HTML=$(cat post_content.html)
      
      cat > "$out/blog/${lib.removeSuffix ".md" post.name}/index.html" << EOF
${baseTemplate {
        title = post.title;
        description = post.description;
        url = post.fullUrl;
        type = "article";
        content = postTemplate {
          inherit (post) title date author tags;
          content = "\$POST_HTML";
        };
      }}
EOF
    ''
  ) sortedPosts;
  
  # Tag pages - individual derivations for each tag
  tagIndexPage = pkgs.runCommand "tag-index" {} ''
    mkdir -p $out/tags
    cat > $out/tags/index.html << 'EOF'
${baseTemplate {
      title = "Tags";
      content = tagIndexTemplate;
    }}
EOF
  '';
  
  # Individual tag pages using the derivation approach
  tagPages = lib.mapAttrsToList (tag: posts:
    pkgs.runCommand "tag-${tag}" {} ''
      mkdir -p "$out/tags/${tag}"
      cat > "$out/tags/${tag}/index.html" << 'EOF'
${baseTemplate {
        title = "Tag: ${tag}";
        content = tagPageTemplate tag posts;
      }}
EOF
    ''
  ) postsByTag;
  
  # Generate clean HTML content for each post for RSS feeds
  # Applies RSS-specific cleaning to make content compatible with feed readers
  rssPostContents = lib.genAttrs (map (p: p.name) sortedPosts) (postName:
    let 
      post = lib.findFirst (p: p.name == postName) null sortedPosts;
      # First convert markdown to HTML (same as website)
      rawHtml = builtins.readFile (pkgs.runCommand "rss-${postName}" { buildInputs = [ pkgs.pandoc ]; } ''
        cat > post.md << 'EOF'
${post.content}
EOF
        pandoc -f markdown -t html --highlight-style=tango post.md > $out
      '');
      # Then clean the HTML for RSS compatibility
      cleanedHtml = cleanRssContent rawHtml;
    in cleanedHtml
  );
  
  # Clean RSS feed generation using writeTextFile
  rssFeed = pkgs.writeTextFile {
    name = "rss-feed";
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
          <title>${lib.escapeXML config.title}</title>
          <link>${constants.baseUrl}/</link>
          <description>${lib.escapeXML config.description}</description>
          <language>${config.language}</language>
          <copyright>${lib.escapeXML config.copyright}</copyright>
          <lastBuildDate>${builtins.readFile (pkgs.runCommand "rss-date" {} "${pkgs.coreutils}/bin/date -R > $out")}</lastBuildDate>
          <atom:link href="${constants.rssUrl}" rel="self" type="application/rss+xml" />
          ${lib.concatStringsSep "\n" (map (post:
            let
              rssDate = builtins.readFile (pkgs.runCommand "rss-date-${post.name}" {} ''
                ${pkgs.coreutils}/bin/date -R -d '${post.date}' > $out
              '');
            in ''
        <item>
          <title>${lib.escapeXML post.title}</title>
          <link>${constants.baseUrl}${post.url}</link>
          <guid isPermaLink="true">${constants.baseUrl}${post.url}</guid>
          <pubDate>${rssDate}</pubDate>
          ${if post.author != "" then "<author>${config.email} (${lib.escapeXML post.author})</author>" else ""}
          <description><![CDATA[${rssPostContents.${post.name}}]]></description>
        </item>''
          ) (lib.take 20 sortedPosts))}
        </channel>
      </rss>
    '';
    destination = "/rss.xml";
  };
  
  # Sitemap generation
  sitemap = pkgs.writeTextFile {
    name = "sitemap";
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>${constants.baseUrl}/</loc>
          <changefreq>weekly</changefreq>
          <priority>1.0</priority>
        </url>
        <url>
          <loc>${constants.baseUrl}/blog/</loc>
          <changefreq>daily</changefreq>
          <priority>0.8</priority>
        </url>
        <url>
          <loc>${constants.baseUrl}/tags/</loc>
          <changefreq>weekly</changefreq>
          <priority>0.6</priority>
        </url>
        ${lib.concatStringsSep "\n" (map (post: ''
        <url>
          <loc>${constants.baseUrl}${post.url}</loc>
          <lastmod>${post.date}</lastmod>
          <changefreq>monthly</changefreq>
          <priority>0.7</priority>
        </url>'') sortedPosts)}
        ${lib.concatStringsSep "\n" (map (tag: ''
        <url>
          <loc>${constants.baseUrl}/tags/${tag}/</loc>
          <changefreq>weekly</changefreq>
          <priority>0.5</priority>
        </url>'') allTags)}
      </urlset>
    '';
    destination = "/sitemap.xml";
  };

  # The final blog derivation
  blog = pkgs.symlinkJoin {
    name = "kimb-blog";
    paths = [ 
      mainIndexPage 
      blogIndexPage 
      tagIndexPage
      sitemap
      rssFeed
    ] ++ postPages ++ tagPages;
  };

in 
  # Return both the blog and internal functions for testing
  # When used as a derivation, Nix will use the blog attribute
  blog // {
    # Expose internal functions for testing
    __funcs = {
      inherit extractMeta cleanRssContent parseTags extractDescription;
    };
  }