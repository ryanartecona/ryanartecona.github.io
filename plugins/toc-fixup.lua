-- the builtin toc plugin puts id slugs on headings, generates a table of
-- contents linking to them, inserts the toc into a container, and also inserts
-- heading anchor links next to each header. but it only does any of this if it
-- finds a container with the toc selector you give it.
--
-- I want all posts to have linkable headings and heading anchor links, but only
-- some (long ones, reference style) to display the toc to readers, so here's
-- the strat.
--
-- 1. put the toc container ('div#toc') in the post.html template, so all posts
--    get a toc and linkable headings at first.
-- 2. put a custom `<toc />` element, the "toc trigger", in only the posts where
--    I want the toc itself to display.
-- 3. in this plugin, either find and remove the `<toc />` trigger element so
--    the visible toc stays (when a post enables the toc), or else find and
--    remove the toc itself (when a post doesn't) which still leaves linkable
--    headings behind.

toc_container_selector = config["toc_container_selector"]
if not toc_container_selector then
  Plugin.fail("No toc_container_selector given.")
end

toc_trigger_selector = config["toc_trigger_selector"]
if not toc_trigger_selector then
  Plugin.fail("No toc_trigger_selector given.")
end

toc_trigger = HTML.select_one(page, toc_trigger_selector)
if toc_trigger then
  HTML.delete(toc_trigger)
else
  toc_container = HTML.select_one(page, toc_container_selector)
  if toc_container then
    HTML.delete(toc_container)
  end
end
