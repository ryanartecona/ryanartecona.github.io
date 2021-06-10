-- Highlights the link to the current page/section in the navigation menu
-- If you have <a href="/about">, it will add a CSS class to it on page site/about.html
-- It assumes you are using relative links
--
-- Sample configuration:
-- [plugins.active-link-hightlight]
--   active_link_class = "active"
--   nav_menu_selector = "nav"
--
-- Minimum soupault version: 1.6
-- Author: Daniil Baturin
-- License: MIT

active_item_class = config["active_item_class"]
menu_selector = config["menu_selector"]
item_selector = config["item_selector"]

if (not active_item_class) then
  Log.warning("active_item_class option is not set, using default (\"active\")")
  active_item_class = "active"
end

if (not menu_selector) then
  Log.warning("menu_selector option is not set, using default (\"nav\")")
  menu_selector = "nav"
end

if (not item_selector) then
  Log.warning("item_selector option is not set, using default (\"a\")")
  item_selector = "a"
end

menu = HTML.select_one(page, menu_selector)
if (not menu) then
  Plugin.exit("No element matched selector " .. menu_selector .. ", nothing to do")
end


items = HTML.select(menu, item_selector)

local index = 1
while items[index] do
  item = items[index]

  href = HTML.get_attribute(HTML.select_one(item, "a"), "href")

  if not href then
    -- Link has no href attribute, ignore
  else
    href = strlower(href)

    -- Remove leading and trailing slashes
    href = Regex.replace_all(href, "(\\/?$|^\\/)", "")
    page_url = Regex.replace_all(page_url, "(\\/?$|^\\/)", "")

    -- Normalize slashes
    href = Regex.replace_all(href, "\\/+", "\\/")

    Log.info(format("visiting nav link: %s (page_url: %s)", href, page_url))

    -- Edge case: the / link that becomes "" after normalization
    -- Anything would match the empty string and higlight all links,
    -- so we handle this case explicitly
    if ((page_url == "") and (href == ""))
      or ((href ~= "") and Regex.match(page_url, "^" .. href))
    then
      HTML.add_class(item, active_item_class)
    end
  end

  index = index + 1
end
