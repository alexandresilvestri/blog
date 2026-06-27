User.find_or_create_by!(email: 'airtontunni@gmail.com')

if Rails.env.development?
  Post.destroy_all

  images = Rails.root.join('db/seed_imgs').children.select(&:file?).sort

  posts = [
    { title: 'Getting Started with Rails 8',
      intro: 'Rails 8 ships with a refreshed default stack and fewer moving parts. ' \
             'In this post we walk through the first hour of a brand-new application ' \
             'and the conventions that keep it tidy.' },
    { title: 'Why I Switched to Action Text',
      intro: 'Rich content used to mean wiring up a third-party editor and praying. ' \
             'Action Text bundles Trix and Active Storage so embedded images just work.' },
    { title: 'A Practical Guide to Active Storage',
      intro: 'Uploads, variants and direct uploads can feel like magic until they break. ' \
             "Here's how the pieces fit together and where the blobs actually live." },
    { title: 'Designing for Mobile First',
      intro: 'Most readers arrive on a phone, so the small screen is the real design. ' \
             'Start narrow, then let the layout breathe as the viewport grows.' },
    { title: 'Postgres Tips Every Developer Should Know',
      intro: 'A handful of Postgres habits pay for themselves on day one. ' \
             'Indexes, UUID keys and sensible defaults top the list.' },
    { title: 'The Art of Writing Clean Migrations',
      intro: 'Migrations are append-only history, so reversibility matters. ' \
             'Small, focused changes keep the schema readable a year from now.' },
    { title: 'Deploying to a VPS Without the Headache',
      intro: 'You do not need a sprawling platform to ship a blog. ' \
             'A single VPS, a reverse proxy and a deploy script go a long way.' },
    { title: 'Understanding UUID Primary Keys',
      intro: 'Sequential integers leak information and collide across systems. ' \
             'UUIDs trade a little space for portability and safer URLs.' },
    { title: 'Testing Rails Apps with RSpec',
      intro: 'Fast, honest tests are the difference between dread and confidence. ' \
             'Request specs cover the most ground for the least effort.' },
    { title: 'Building a Blog from Scratch',
      intro: 'Sometimes the best way to learn a framework is to build the obvious thing. ' \
             'A blog touches models, views, uploads and routing all at once.' }
  ]

  posts.each_with_index do |attrs, i|
    image = images[i]
    blob = ActiveStorage::Blob.create_and_upload!(
      io: image.open,
      filename: image.basename.to_s,
      content_type: Marcel::MimeType.for(image)
    )
    body = ActionText::Content.new("<p>#{attrs[:intro]}</p>").append_attachables(blob)
    date = (i * 18).days.ago
    Post.create!(title: attrs[:title], body: body, created_at: date, updated_at: date)
  end
end
