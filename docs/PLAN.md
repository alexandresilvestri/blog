# Blog Implementation Plan

> Rails 8.1.3 + Tailwind v4 + PostgreSQL + TipTap (JSONB AST) + S3 + Pagefind + Disqus.
> Single-author. Kamal/VPS deploy.

---

## 0. Stack Snapshot

| Layer | Choice |
|---|---|
| Framework | Rails 8.1.3 |
| Ruby | per `.ruby-version` |
| DB | PostgreSQL 16+ |
| CSS | `tailwindcss-rails ~> 4.4` (Tailwind v4, CSS-first `@theme`) |
| JS bundler | **swap `importmap-rails` → `jsbundling-rails` (esbuild)** for TipTap |
| Background jobs | Solid Queue (already in Gemfile) |
| Cache / cable | Solid Cache, Solid Cable |
| Object storage | S3 via `aws-sdk-s3` + Active Storage direct upload |
| Editor | TipTap (ProseMirror) — JSON AST source of truth |
| Search | Pagefind (static index, ⌘K modal) |
| Comments | Disqus (client-side embed, id-keyed) |
| Deploy | Kamal 2 (config already present in `.kamal/`) |
| Tests | RSpec, Capybara, Selenium |

Already present: `bcrypt`, `image_processing`, `puma`, `bootsnap`, `thruster`, `propshaft`, `turbo-rails`, `stimulus-rails`, `kamal`, `brakeman`, `bundler-audit`, `rubocop-rails-omakase`.

To add (Gemfile): `aws-sdk-s3`, `jsbundling-rails`, `rack-attack`.
To remove from Gemfile: `importmap-rails`.

---

## 1. Data Model

### 1.1 `posts`

```ruby
create_table :posts do |t|
  t.string  :title,          null: false
  t.string  :slug,           null: false
  t.string  :status,         null: false, default: "draft"   # draft | published | archived
  t.datetime :published_at
  t.jsonb   :content_doc,    null: false, default: {}        # TipTap ProseMirror AST
  t.text    :rendered_html                                    # cached SSR output
  t.text    :plain_text                                       # extracted for search/excerpt
  t.string  :excerpt,        limit: 320
  t.integer :schema_version, null: false, default: 1
  t.timestamps
end
add_index :posts, :slug, unique: true
add_index :posts, :status
add_index :posts, :published_at
add_index :posts, :content_doc, using: :gin
add_index :posts,
          "to_tsvector('simple', plain_text)",
          using: :gin,
          name:  "idx_posts_fts"
```

Notes:
- `slug` immutable post-publish.
- `plain_text` populated by extractor; supports Postgres FTS fallback even though Pagefind is primary.
- `rendered_html` regenerated in `before_save` when `content_doc_changed?`.
- No author table — single user. Auth via `http_basic_authenticate_with` on `/admin/*`.

### 1.2 Tags (join model)

```ruby
create_table :tags do |t|
  t.string :name, null: false
  t.string :slug, null: false
  t.timestamps
end
add_index :tags, :slug, unique: true
add_index :tags, :name, unique: true

create_table :taggings do |t|
  t.references :post, null: false, foreign_key: true
  t.references :tag,  null: false, foreign_key: true
  t.timestamps
end
add_index :taggings, [:post_id, :tag_id], unique: true
```

```ruby
class Post < ApplicationRecord
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
end

class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy
  has_many :posts, through: :taggings
  before_validation :set_slug
  validates :name, :slug, presence: true, uniqueness: true

  private

  def set_slug
    self.slug ||= name.to_s.parameterize
  end
end

class Tagging < ApplicationRecord
  belongs_to :post
  belongs_to :tag
end
```

No categories. Future topic-grouping handled by tags.

### 1.3 Embedded assets in AST

Image node JSON shape:

```json
{
  "type": "image",
  "attrs": {
    "blob_signed_id": "eyJfcmFpbHMiOnsibWVzc2FnZSI6...",
    "alt": "...",
    "width": 1600,
    "height": 900
  }
}
```

Store Active Storage `signed_id` — bucket move = config change, no JSON rewrite. Renderer resolves at render time, output cached in `rendered_html`.

No cover image column.

### 1.4 Render storage

Persisted `rendered_html` column. Reasons: Pagefind needs static HTML, single source for show view + RSS + Pagefind crawler, trivial invalidation via `before_save`.

---

## 2. Editor (TipTap)

### 2.1 Bundling — swap to esbuild

Importmaps cannot resolve TipTap's deep ESM tree cleanly. Migrate:

```bash
bundle remove importmap-rails
bundle add jsbundling-rails
bin/rails javascript:install:esbuild
```

Tailwind stays via `tailwindcss-rails` (separate pipeline).

### 2.2 Extensions

Enable: `StarterKit`, `Link` (`openOnClick: false`, `autolink: true`), custom `Image`, `Placeholder`, `CharacterCount`, `Typography`.

Skip: Table, Mention, Collaboration, TaskList, Color, Highlight, Underline, Youtube (per "no embeds").

### 2.3 Editor → server flow

Stimulus controller wraps editor. JSON serialized to hidden `<input>`. Turbo form submit. Server parses + validates against allowlist before save.

```js
// app/javascript/controllers/editor_controller.js
import { Controller } from "@hotwired/stimulus"
import { Editor } from "@tiptap/core"
import StarterKit from "@tiptap/starter-kit"
// + Link, Image (custom), Placeholder, CharacterCount, Typography

export default class extends Controller {
  static targets = ["mount", "field"]

  connect() {
    this.editor = new Editor({
      element: this.mountTarget,
      extensions: [StarterKit /* ... */],
      content: JSON.parse(this.fieldTarget.value || "{}"),
      onUpdate: () => {
        this.fieldTarget.value = JSON.stringify(this.editor.getJSON())
        this.scheduleAutosave()
      }
    })
  }

  scheduleAutosave() { /* debounce 2s, fetch PATCH /admin/posts/:id/autosave */ }

  disconnect() { this.editor?.destroy() }
}
```

Autosave: separate `PATCH /admin/posts/:id/autosave` endpoint. Returns 204. Same validation pipeline.

### 2.4 Image upload — Active Storage direct upload

1. Custom TipTap `Image` extension hooks paste/drop.
2. `@rails/activestorage` `DirectUpload` posts directly to S3 via presigned URL.
3. Returned blob `signed_id` inserted into image node attrs.

S3 config (`config/storage.yml`):

```yaml
amazon:
  service: S3
  access_key_id: <%= ENV["AWS_ACCESS_KEY_ID"] %>
  secret_access_key: <%= ENV["AWS_SECRET_ACCESS_KEY"] %>
  region: <%= ENV["AWS_REGION"] %>
  bucket: <%= ENV["AWS_BUCKET"] %>
```

Bucket CORS allowing `PUT` from app domain. Versioning enabled on bucket.

### 2.5 Server-side validation/sanitization

```ruby
class TiptapDocumentValidator
  ALLOWED_NODES = %w[
    doc paragraph heading bulletList orderedList listItem
    blockquote codeBlock horizontalRule hardBreak text image
  ].freeze
  ALLOWED_MARKS = %w[bold italic strike code link].freeze
  ALLOWED_HEADING_LEVELS = [2, 3, 4].freeze   # h1 reserved for post title

  Invalid = Class.new(StandardError)

  def self.validate!(doc)
    raise Invalid, "root must be doc" unless doc["type"] == "doc"
    walk(doc)
  end

  def self.walk(node)
    raise Invalid, "node #{node["type"]}" unless ALLOWED_NODES.include?(node["type"])

    (node["marks"] || []).each do |m|
      raise Invalid, "mark #{m["type"]}" unless ALLOWED_MARKS.include?(m["type"])
    end

    if node["type"] == "image"
      raise Invalid, "image needs blob_signed_id" unless node.dig("attrs", "blob_signed_id")
    end

    if node["type"] == "heading"
      level = node.dig("attrs", "level")
      raise Invalid, "heading level" unless ALLOWED_HEADING_LEVELS.include?(level)
    end

    (node["content"] || []).each { |child| walk(child) }
  end
end
```

Run in `before_validation`. Cap document size (1 MB JSON) at controller level. `rack-attack` throttles autosave + admin login.

---

## 3. SSR: AST → HTML in Ruby

### 3.1 Renderer choice

Custom Ruby visitor over JSONB. Rejected: `mini_racer` (V8 deploy weight, cold start), Node sidecar (extra service on VPS).

### 3.2 Renderer (dispatch table)

```ruby
class TiptapRenderer
  NODE_RENDERERS = {
    "doc"            => ->(n, r) { r.render_children(n) },
    "paragraph"      => ->(n, r) { r.tag(:p, r.render_children(n)) },
    "heading"        => ->(n, r) { r.tag("h#{n.dig("attrs", "level")}", r.render_children(n)) },
    "bulletList"     => ->(n, r) { r.tag(:ul, r.render_children(n)) },
    "orderedList"    => ->(n, r) { r.tag(:ol, r.render_children(n)) },
    "listItem"       => ->(n, r) { r.tag(:li, r.render_children(n)) },
    "blockquote"     => ->(n, r) { r.tag(:blockquote, r.render_children(n)) },
    "codeBlock"      => ->(n, r) { r.code_block(n) },
    "horizontalRule" => ->(_, _) { "<hr>".html_safe },
    "hardBreak"      => ->(_, _) { "<br>".html_safe },
    "text"           => ->(n, r) { r.text_with_marks(n) },
    "image"          => ->(n, r) { r.image(n) }
  }.freeze

  MARK_RENDERERS = {
    "bold"   => ->(s, _) { "<strong>#{s}</strong>" },
    "italic" => ->(s, _) { "<em>#{s}</em>" },
    "strike" => ->(s, _) { "<s>#{s}</s>" },
    "code"   => ->(s, _) { "<code>#{s}</code>" },
    "link"   => ->(s, m) {
      href = ERB::Util.html_escape(m.dig("attrs", "href"))
      %(<a href="#{href}" rel="noopener nofollow">#{s}</a>)
    }
  }.freeze

  def render(doc)           = NODE_RENDERERS["doc"].call(doc, self).html_safe
  def render_children(node) = (node["content"] || []).map { |n| render_node(n) }.join.html_safe
  def render_node(node)     = NODE_RENDERERS.fetch(node["type"]).call(node, self)

  def text_with_marks(node)
    txt = ERB::Util.html_escape(node["text"])
    (node["marks"] || []).reduce(txt) { |acc, m| MARK_RENDERERS[m["type"]].call(acc, m) }
  end

  def image(node)
    blob = ActiveStorage::Blob.find_signed!(node.dig("attrs", "blob_signed_id"))
    url  = Rails.application.routes.url_helpers.rails_blob_url(
             blob, host: Rails.application.config.action_controller.default_url_options[:host]
           )
    alt  = ERB::Util.html_escape(node.dig("attrs", "alt"))
    w    = node.dig("attrs", "width")
    h    = node.dig("attrs", "height")
    %(<img src="#{url}" alt="#{alt}" width="#{w}" height="#{h}" loading="lazy" decoding="async">).html_safe
  end

  def code_block(node)
    text = ERB::Util.html_escape(node["content"]&.first&.dig("text").to_s)
    lang = ERB::Util.html_escape(node.dig("attrs", "language") || "")
    %(<pre><code class="language-#{lang}">#{text}</code></pre>).html_safe
  end

  def tag(name, inner) = %(<#{name}>#{inner}</#{name}>).html_safe
end
```

Plain-text extractor mirrors structure. Returns single string for `plain_text` column + excerpt.

### 3.3 Output safety

- All text/attrs through `ERB::Util.html_escape`.
- Final `rendered_html` passed through `Rails::HTML5::SafeListSanitizer` before persistence (belt + suspenders).
- Link attrs: `href` only; force `rel="noopener nofollow"`; strip `target`.
- No raw HTML node accepted (not in allowlist).

### 3.4 Caching

```ruby
class Post < ApplicationRecord
  before_validation :validate_doc
  before_save :rerender, if: :content_doc_changed?

  def rerender
    self.rendered_html = TiptapRenderer.new.render(content_doc)
    self.plain_text    = TiptapPlainText.new.extract(content_doc)
    self.excerpt     ||= plain_text.truncate(280, separator: " ")
  end

  private

  def validate_doc
    TiptapDocumentValidator.validate!(content_doc)
  rescue TiptapDocumentValidator::Invalid => e
    errors.add(:content_doc, e.message)
  end
end
```

Show view: `<%= @post.rendered_html.html_safe %>`. Bytes already on disk — no fragment cache needed.

Code highlighting: client-side via Prism on post show pages only (esbuild dynamic import).

---

## 4. Search

### 4.1 Pagefind primary

1. `bin/rails posts:export_static` — renders each published post's `rendered_html` to `public/_pagefind_source/<slug>.html` with minimal layout.
2. Post-deploy: `npx pagefind --site public/_pagefind_source --output-path public/pagefind`.
3. Show view loads Pagefind UI from `public/pagefind/` — only when ⌘K modal opens (dynamic import).

Trigger: `after_commit` on `Post` enqueues a Solid Queue job to re-export + re-index. Or rebuild on Kamal deploy.

### 4.2 Postgres fallback / admin queries

```ruby
# all posts containing code blocks
Post.where(<<~SQL)
  jsonb_path_exists(content_doc, '$.** ? (@.type == "codeBlock")')
SQL

# plain-text fallback
Post.where(
  "to_tsvector('simple', plain_text) @@ plainto_tsquery(?)", q
)
```

### 4.3 Excerpt

`plain_text.truncate(280, separator: " ")` on save. Optional manual override via form field.

---

## 5. Disqus

- Client embed in `app/views/posts/show.html.erb`.
- Identifier id-keyed (never slug):
  ```js
  var disqus_config = function () {
    this.page.url        = "https://yoursite.com/posts/<%= @post.id %>";
    this.page.identifier = "post_<%= @post.id %>";
  };
  ```
- Lazy-load script via IntersectionObserver near comments anchor.
- Nothing in DB.

---

## 6. Migration & Versioning

### 6.1 Schema versioning

`posts.schema_version` integer. Renderer + validator dispatch per version when AST shape changes:

```ruby
case post.schema_version
when 1 then TiptapRenderer::V1.new.render(post.content_doc)
when 2 then TiptapRenderer::V2.new.render(post.content_doc)
end
```

Adding new node type: bump `SCHEMA_VERSION`, write data migration job (Solid Queue) that walks rows and transforms `content_doc`, sets `schema_version = 2`.

### 6.2 Backup

- Daily `pg_dump` to S3 (Kamal accessory or systemd timer).
- Weekly `bin/rails posts:export_jsonl` — `{id, slug, content_doc, rendered_html, ...}` per line, separate bucket.
- AS blobs: bucket versioning enabled.

---

## 7. Design Integration (from handoff bundle)

### 7.1 Tailwind v4 — CSS-first config

`tailwindcss-rails ~> 4.4` = Tailwind **v4**. No `tailwind.config.js`. Theme tokens go in `app/assets/tailwind/application.css` via `@theme`:

```css
@import "tailwindcss";

@theme {
  --color-paper-50:  #FBFAF7;
  --color-paper-100: #F4F2EC;
  --color-paper-200: #E8E5DC;
  --color-paper-300: #D5D1C5;
  --color-paper-400: #A8A496;
  --color-paper-500: #7A7668;
  --color-paper-600: #56534A;
  --color-paper-700: #3A3833;
  --color-paper-800: #22211E;
  --color-paper-900: #151412;       /* fix design's '#15141200' typo */

  --color-ink-50:  #E8EAF0;
  --color-ink-100: #C8CCD6;
  --color-ink-200: #9097A6;
  --color-ink-300: #5F6675;
  --color-ink-400: #3A404D;
  --color-ink-500: #262B36;
  --color-ink-600: #1B1F28;
  --color-ink-700: #13161D;
  --color-ink-800: #0E1015;
  --color-ink-900: #08090C;

  --color-accent-50:  #EEF0FB;
  --color-accent-100: #D8DDF5;
  --color-accent-200: #B5BEEC;
  --color-accent-300: #8B97DD;
  --color-accent-400: #6573CC;
  --color-accent-500: #4A57B8;
  --color-accent-600: #3A4699;
  --color-accent-700: #2E377A;
  --color-accent-800: #232A5C;
  --color-accent-900: #181D40;

  --font-sans:  "Inter", ui-sans-serif, system-ui, sans-serif;
  --font-serif: "Source Serif 4", Georgia, serif;
  --font-mono:  "JetBrains Mono", ui-monospace, SFMono-Regular, monospace;

  --container-prose-narrow: 38rem;   /* exposed as max-w-prose-narrow */
  --container-prose-wide:   46rem;
  --container-archive:      52rem;

  --tracking-tightest: -0.03em;

  /* font-size scale per design — set as separate --text-* tokens */
}

/* @plugin "@tailwindcss/typography"; */
@plugin "@tailwindcss/typography";

@variant dark (&:where(.dark, .dark *));
```

Dark mode: class-based via `@variant dark` declaration above. Tailwind v4 default is `media`; design needs class-based for the toggle.

### 7.2 Fonts

Add to `app/views/layouts/application.html.erb` `<head>`:

```erb
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&family=Source+Serif+4:opsz,wght@8..60,400;8..60,500;8..60,600;8..60,700&display=swap" rel="stylesheet">
```

Theme pre-paint script (FOUC prevention) — inline in `<head>` before stylesheet:

```erb
<script>
  (function(){
    var s=localStorage.getItem('theme');
    var d=window.matchMedia('(prefers-color-scheme: dark)').matches;
    if(s==='dark'||(!s&&d))document.documentElement.classList.add('dark');
  })();
</script>
```

### 7.3 Layouts → Rails views

| Design file | Rails location |
|---|---|
| `index.html` | layout: `app/views/layouts/application.html.erb` (header/footer) + view: `app/views/posts/index.html.erb` |
| `post.html`  | view: `app/views/posts/show.html.erb` |
| `about.html` | view: `app/views/pages/about.html.erb` |

Shared partials: `app/views/shared/_header.html.erb`, `_footer.html.erb`.

Theme toggle → Stimulus controller `app/javascript/controllers/theme_controller.js`.

### 7.4 Routes

```ruby
Rails.application.routes.draw do
  root "posts#index"

  resources :posts, only: [:index, :show], param: :slug
  get "/tag/:slug", to: "tags#show", as: :tag
  get "/about",     to: "pages#about", as: :about
  get "/feed.xml",  to: "feeds#show",  defaults: { format: :rss }

  namespace :admin do
    resources :posts do
      member { patch :autosave }
    end
    resources :tags
    direct_upload_to: ActiveStorage::DirectUploadsController # confirm in mount
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
```

### 7.5 Controllers

```ruby
class PostsController < ApplicationController
  def index
    @posts_by_year = Post.published
                         .order(published_at: :desc)
                         .group_by { |p| p.published_at.year }
  end

  def show
    @post = Post.published.find_by!(slug: params[:slug])
    @prev = Post.published.where("published_at < ?", @post.published_at).order(published_at: :desc).first
    @next = Post.published.where("published_at > ?", @post.published_at).order(:published_at).first
  end
end

class TagsController < ApplicationController
  def show
    @tag = Tag.find_by!(slug: params[:slug])
    @posts_by_year = @tag.posts.published
                         .order(published_at: :desc)
                         .group_by { |p| p.published_at.year }
    render "posts/index"
  end
end
```

### 7.6 Placeholder mapping

| Design placeholder | ERB |
|---|---|
| `{{ post.title }}` | `<%= post.title %>` |
| `{{ post.date \| date: "%b %d, %Y" }}` | `<%= post.published_at.strftime("%b %d, %Y") %>` |
| `{{ post.body \| markdown }}` | `<%= post.rendered_html.html_safe %>` (AST-rendered, not Markdown) |
| `{{ post.excerpt }}` | `<%= post.excerpt %>` |
| `{{ post.tags }}` | iterate `@post.tags`, link `tag_path(tag)` |
| `{{ post.category }}` (post header eyebrow) | replace with `<%= @post.read_minutes %> min read` |
| Cover `<figure>` block | delete entirely |
| `{{ year }}` / `{{ posts.size }}` | `<%= year %>` / `<%= posts.size %>` |

`Post#read_minutes`:

```ruby
def read_minutes
  ((plain_text.to_s.split.size / 200.0).ceil).clamp(1, Float::INFINITY).to_i
end
```

### 7.7 ⌘K modal → Pagefind

Stimulus controller `search_controller.js`:
- Listens for `Cmd/Ctrl+K` keydown globally.
- Opens `<dialog>` modal.
- First open → dynamic `import("/pagefind/pagefind-ui.js")`, mounts UI keyed to `#pf-search`.
- Modal styling: paper-50 / ink-700 surfaces, accent-500 highlights, mono font for kbd hints.

### 7.8 Mobile

- Header: hide GitHub link below `sm:` breakpoint to avoid overflow on <420px.
- Post row grid: design already responsive (`grid-cols-[7rem_1fr] md:grid-cols-[9rem_1fr]`).
- Cover figure removed — irrelevant.

---

## 8. Risks & Trade-offs

### JSONB+AST vs HTML vs Markdown

| Concern | JSONB+AST | HTML in text | Markdown |
|---|---|---|---|
| Editor fidelity | Lossless TipTap | Editor-dependent | Markdown editor only |
| Server queryability | Strong (`jsonb_path_exists`) | Weak (regex) | Weak |
| Render cost | Custom renderer (~150 LOC) | Zero | Parser per render |
| Portability away from TipTap | Painful (ProseMirror-specific) | Easy | Easy |
| Migration when nodes evolve | Versioned migrations | None | None |
| Sanitization clarity | Allowlist by node type | Mixed parser+sanitizer | Mostly clean |

**Verdict:** AST chosen for structural queries + versioning. Cost = ~200 LOC renderer + validator. Worth it.

### vs ActionText

ActionText hybrid (TipTap frontend, HTML in `action_text_rich_texts`):
- **Pro:** free attachment lifecycle, free purging, free cache key invalidation.
- **Con:** lose JSON AST (TipTap → HTML round-trip lossy), no structural queries, drift on re-edit.

Lift one ActionText idea: write a `posts_blobs` join populated from a renderer-walk, so AS knows which blobs belong to which post (purging, cache eviction).

---

## 9. Build Order (Final)

> Repo already Rails-scaffolded; skip `rails new`.

| # | Step | Verify |
|---|---|---|
| 1 | Tailwind v4 `@theme` tokens in `app/assets/tailwind/application.css` (paper/ink/accent palettes, fonts, max-widths, dark variant, typography plugin) | `bin/rails tailwindcss:build` succeeds; classes resolve |
| 2 | Google Fonts preconnect + theme pre-paint script in `app/views/layouts/application.html.erb` | Light/dark toggle no FOUC |
| 3 | Shared `_header.html.erb`, `_footer.html.erb`; static `pages#about`; static `posts#index` + `posts#show` with hardcoded sample data | All three pages render, match design pixel-close |
| 4 | Theme toggle Stimulus controller; localStorage persist; `prefers-color-scheme` fallback | Toggle persists across reload |
| 5 | Migrations: `posts`, `tags`, `taggings`. Models: `Post`, `Tag`, `Tagging` with associations + slug callbacks | `bin/rails db:migrate` clean; `Post.create!(...)` works |
| 6 | Admin auth via `http_basic_authenticate_with` on `/admin/*`. CRUD scaffolded with raw textarea for `content_doc` | Can save/edit/delete a post via `/admin/posts` |
| 7 | `TiptapDocumentValidator`, `TiptapRenderer`, `TiptapPlainText`. RSpec specs against fixture JSON docs covering every node + mark | All node/mark cases covered green |
| 8 | `before_validation :validate_doc`, `before_save :rerender`. `rendered_html` populated on save | `Post#rendered_html` matches expected HTML for fixture docs |
| 9 | Wire `posts/index` (year-grouped via controller `group_by(&:year)`) + `posts/show` `.prose` body to real DB | Visit `/`, see real posts; visit `/posts/:slug`, see rendered HTML |
| 10 | Tags CRUD in admin; tag chips on `posts/show`; `/tag/:slug` archive (reuses index view) | Tag link from post navigates to filtered archive |
| 11 | Swap `importmap-rails` → `jsbundling-rails` (esbuild). Install `@hotwired/turbo-rails`, `@hotwired/stimulus`, `@rails/activestorage`, `@tiptap/core`, `@tiptap/starter-kit`, `@tiptap/extension-link`, `@tiptap/extension-image`, `@tiptap/extension-placeholder`, `@tiptap/extension-character-count`, `@tiptap/extension-typography` | `bin/dev` boots; existing JS still works |
| 12 | Stimulus `editor_controller.js`. Hidden field carries JSON. Replace admin textarea with TipTap mount | Editor renders, toolbar works, save round-trips JSON |
| 13 | Autosave: `PATCH /admin/posts/:id/autosave`, debounced 2s, returns 204. `rack-attack` throttle | Edits persist without manual save |
| 14 | Active Storage S3 service config. CORS on bucket. `aws-sdk-s3` gem. `@rails/activestorage` direct upload + custom TipTap Image extension | Drop image into editor, S3 PUT succeeds, image renders in show view |
| 15 | Pagefind: `posts:export_static` rake task; `after_commit` job triggers export + `npx pagefind` index; ⌘K Stimulus modal lazy-imports Pagefind UI | Search in modal returns published-post results |
| 16 | Disqus client embed, id-keyed config, IntersectionObserver lazy-load on `posts/show` | Comments thread loads on scroll-near |
| 17 | RSS feed: `feeds#show`, `respond_to :rss`, builder template | `/feed.xml` validates |
| 18 | Prism (or highlight.js) on `posts/show` only via dynamic import, theme styled | Code blocks highlight client-side |
| 19 | Schema versioning scaffolding (`Post#schema_version`, renderer dispatch) | Versioned renderer wired even at v1 |
| 20 | Backup tasks: `pg_dump` cron, `posts:export_jsonl`, S3 bucket versioning | Restore drill from JSONL succeeds |
| 21 | Kamal deploy config refresh; post-deploy hook runs Pagefind index | Production deploy green; ⌘K works in prod |

Steps 1–10 = visual MVP with real data, no editor.
Steps 11–14 = full editor + image pipeline.
Steps 15–18 = search + comments + feed + highlight.
Steps 19–21 = hardening.

---

## 10. Open Questions / Defer

- **Admin auth hardening**: `http_basic` good for v1. Upgrade to `has_secure_password` + session cookie if exposing more admin surface later.
- **Multi-image-per-post lifecycle**: orphan blob cleanup. Renderer-walk → `posts_blobs` join solves; defer to step 14 or post-launch.
- **i18n**: design uses `lang="pt-BR"` and "Sobre" label. Confirm Portuguese-only or bilingual.
- **Reading time accuracy**: `200 wpm` heuristic. Tune later if content drifts.
