-- Soupault currently doesn't support rendering index field variables directly
-- into the page template (https://github.com/dmbaturin/soupault/issues/36).
-- This plugin manually works around that by moving html around for the one
-- post template I care about, with hardcoded selectors.


-- selector = [".page-content h1#post-title", ".page-content h1"]
post_title_elem = HTML.select_one(page, ".page-content h1#post-title") 
  or HTML.select_one(page, ".page-content h1")
if not post_title_elem then
  Plugin.fail("Couldn't find a post title")
else
  post_title = HTML.inner_html(post_title_elem)
end

-- selector = [".page-content date#post-date", ".page-content date"]
post_date_elem = HTML.select_one(page, ".page-content date#post-date")
  or HTML.select_one(page, ".page-content date")
if not post_date_elem then
  Plugin.fail("Couldn't find a post date")
else
  post_date_raw = HTML.inner_html(post_date_elem)
end

-- selector = [".page-content tags#post-tags", ".page-content tags"]
post_tags_elem = HTML.select_one(page, ".page-content tags#post-tags")
  or HTML.select_one(page, ".page-content tags")
if not post_tags_elem then
  post_tags = ""
else
  post_tags = HTML.inner_html(post_tags_elem)
end


-- move title to the right place, and delete its previous location
post_title_target = HTML.select_one(page, ".entry-header .entry-title")
HTML.replace_content(post_title_target, HTML.parse(post_title))
HTML.delete(post_title_elem)

-- move date to the right place, and delete its previous location
post_date_target = HTML.select_one(page, ".entry-meta .entry-date")
HTML.replace_content(post_date_target, HTML.parse(post_date_raw))
HTML.delete(post_date_elem)

-- move tags to the right place, and delete its previous location
post_tags_target = HTML.select_one(page, ".entry-meta .entry-tags")
HTML.replace_content(post_tags_target, HTML.parse(post_tags))
if post_tags_elem then HTML.delete(post_tags_elem) end
