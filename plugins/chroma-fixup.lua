-- the soupault postprocess_element widget interacts with chroma such that I
-- get a structure like this for highlighted code blocks, which looks like
-- garbage.
--
-- <pre>
--   <code class="language-python">
--     <pre class="chroma">
--       <span class="k"></span>...
--     </pre>
--   </code>
-- </pre>
--
-- This script turns that into this.
--
-- <code class="language-python">
--   <pre class="highlight">
--       <span class="k"></span>...
--   </pre>
-- </code>

highlighted_blocks = HTML.select(page, "pre.chroma")

-- lua 2.5 doesn't have proper for loops
idx = 1
while highlighted_blocks[idx] do
  highlighted_block = highlighted_blocks[idx]

  -- rename class="chroma" to class="highlight", pygments style
  HTML.remove_class(highlighted_block, "chroma")
  HTML.add_class(highlighted_block, "highlight")

  -- remove the redundant outer <pre> wrapper, by copying its content out before
  -- deleting it
  outer = HTML.parent(HTML.parent(highlighted_block))
  HTML.insert_after(outer, HTML.clone_content(outer))
  HTML.delete(outer)

  idx = idx + 1
end
