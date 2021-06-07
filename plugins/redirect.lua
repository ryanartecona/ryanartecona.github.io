Plugin.require_version("2.7")

-- example usage:
-- <redirect href="/about.html" />

template_file = config["template"]
if not template_file then
  Plugin.fail("Template file path unspecified.")
end

element = HTML.select_one(page, "redirect")

if element then
  target = HTML.get_attribute(element, "href")
  if not target then
    -- Log.error("Encountered <redirect> with no href.")
    Plugin.fail("Encountered <redirect> with no href.")
  end
  redirect_template = Sys.read_file("templates/redirect.html")
  redirect_page = HTML.parse(String.render_template(redirect_template, {location=target}))
  -- cannot replace the page with a new page directly, so replace head and body
  HTML.replace(HTML.select_one(page, "head"), HTML.select_one(redirect_page, "head"))
  HTML.replace(HTML.select_one(page, "body"), HTML.select_one(redirect_page, "body"))
end
