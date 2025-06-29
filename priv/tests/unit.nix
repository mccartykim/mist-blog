# Unit tests using lib.runTests
{ lib, generator }:

let
  # Import functions from the generator for testing
  inherit (generator.__funcs) extractMeta cleanRssContent parseTags extractDescription;

  # Test data
  testPost = ''
    ---
    title: Test Post
    date: 2024-01-01
    author: Test Author
    draft: false
    ---

    ## Test Content

    This is a test post.

    * Item 1
    * Item 2
  '';

  testPostNoFrontmatter = ''
    ## Just Content

    No frontmatter here.
  '';

  testEmptyFrontmatter = ''
    ---
    ---

    Just content.
  '';

  testDraftPost = ''
    ---
    title: Draft
    draft: true
    ---

    Draft content.
  '';

  # RSS cleaning test data
  testHtmlWithSidenotes = ''<p>Regular text <span class="sidenote">This is a sidenote</span> more text.</p>'';
  testHtmlWithNote = ''<p>Text with <span class="note">a note</span> here.</p>'';
  testHtmlWithDialogue = ''<div class="dialogue questioner"><p>Hello there!</p></div><div class="dialogue author"><p>Hi back!</p></div>'';
  testHtmlWithComplexClasses = ''<h2 id="section-title">Title</h2><div class="content"><p>Content</p></div>'';

in lib.runTests {
  # Test frontmatter parsing
  testBasicFrontmatter = {
    expr = (extractMeta testPost).meta.title;
    expected = "Test Post";
  };

  testFrontmatterDate = {
    expr = (extractMeta testPost).meta.date;
    expected = "2024-01-01";
  };

  testFrontmatterAuthor = {
    expr = (extractMeta testPost).meta.author;
    expected = "Test Author";
  };

  testFrontmatterDraft = {
    expr = (extractMeta testPost).meta.draft;
    expected = "false";
  };

  testContentExtraction = {
    expr = lib.hasInfix "Test Content" (extractMeta testPost).markdown;
    expected = true;
  };

  testListInContent = {
    expr = lib.hasInfix "* Item 1" (extractMeta testPost).markdown;
    expected = true;
  };

  # Test edge cases
  testNoFrontmatter = {
    expr = (extractMeta testPostNoFrontmatter).meta;
    expected = {};
  };

  testEmptyFrontmatterMeta = {
    expr = (extractMeta testEmptyFrontmatter).meta;
    expected = {};
  };

  testEmptyFrontmatterContent = {
    expr = lib.hasInfix "Just content" (extractMeta testEmptyFrontmatter).markdown;
    expected = true;
  };

  testDraftDetection = {
    expr = (extractMeta testDraftPost).meta.draft;
    expected = "true";
  };

  # Test string processing
  testStringOperations = {
    expr = lib.removePrefix " " " hello";
    expected = "hello";
  };

  testStringSuffix = {
    expr = lib.removeSuffix "'" "hello'";
    expected = "hello";
  };

  # Test XML escaping (for RSS)
  testXmlEscaping = {
    expr = lib.escapeXML "Test & <special> \"chars\"";
    expected = "Test &amp; &lt;special&gt; &quot;chars&quot;";
  };

  testXmlEscapingTitle = {
    expr = lib.escapeXML "Rust's ownership & borrowing";
    expected = "Rust&apos;s ownership &amp; borrowing";
  };

  # RSS content cleaning tests - strips structural tags, keeps semantic ones
  testSidenoteRemoval = {
    expr = cleanRssContent testHtmlWithSidenotes;
    expected = "Regular text This is a sidenote  more text. ";
  };

  testNoteRemoval = {
    expr = cleanRssContent testHtmlWithNote;
    expected = "Text with a note  here. ";
  };

  testDialogueRemoval = {
    expr = cleanRssContent testHtmlWithDialogue;
    expected = "Hello there!  Hi back!  ";
  };

  testComplexClassRemoval = {
    expr = cleanRssContent testHtmlWithComplexClasses;
    expected = "Title Content  ";
  };

  # Test that semantic HTML is preserved (no more p tags)
  testSemanticHtmlPreserved = {
    expr = cleanRssContent "<p><strong>Bold</strong> and <em>italic</em> and <code>code</code></p>";
    expected = "<strong>Bold</strong> and <em>italic</em> and <code>code</code> ";
  };

  # Test complex content with multiple transformations
  testComplexRssClean = {
    expr = cleanRssContent "<p>Text <span class=\"sidenote\">note here</span> more.</p><div class=\"dialogue author\"><p>Quote</p></div>";
    expected = "Text note here  more. Quote  ";
  };
}