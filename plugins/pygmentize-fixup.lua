-- the soupault postprocess_element widget interacts with pygmentize such that I
-- get a structure like this for highlighted code blocks, which looks like
-- garbage.
-- 
-- <pre>
--   <code class="language-python">
--     <div class="highlight">
--       <pre>
--         <span></span>...
--       </pre>
--     </div>
--   </code>
-- </pre>
-- 
-- This script removes the outer <pre> and <code> just leaving the div.highlight

highlighted_blocks = HTML.select(page, "div.highlight")

-- lua 2.5 doesn't have proper for loops
idx = 1
while highlighted_blocks[idx] do
  highlighted_block = highlighted_blocks[idx]
  outer = HTML.parent(HTML.parent(highlighted_block))
  HTML.insert_after(outer, HTML.clone_content(HTML.parent(highlighted_block)))
  HTML.delete(outer)
  idx = idx + 1
end
