User.find_or_create_by!(email: 'airtontunni@gmail.com')

if Rails.env.development?
  Post.destroy_all

  images = Rails.root.join('db/seed_imgs').children.select(&:file?).sort

  posts = [
    { title: 'Primeiros Passos com Rails 8',
      intro: 'O Rails 8 chega com uma pilha padrão renovada e menos peças móveis. ' \
             'Neste post percorremos a primeira hora de uma aplicação novinha em folha ' \
             'e as convenções que a mantêm organizada.',
      title_en: 'Getting Started with Rails 8',
      intro_en: 'Rails 8 ships with a refreshed default stack and fewer moving parts. ' \
                'In this post we walk through the first hour of a brand-new application ' \
                'and the conventions that keep it tidy.' },
    { title: 'Por Que Migrei para o Action Text',
      intro: 'Conteúdo rico costumava significar configurar um editor de terceiros e rezar. ' \
             'O Action Text já inclui o Trix e o Active Storage, então imagens embutidas simplesmente funcionam.',
      title_en: 'Why I Switched to Action Text',
      intro_en: 'Rich content used to mean wiring up a third-party editor and praying. ' \
                'Action Text bundles Trix and Active Storage so embedded images just work.' },
    { title: 'Um Guia Prático de Active Storage',
      intro: 'Uploads, variantes e uploads diretos parecem mágica até quebrarem. ' \
             'Veja como as peças se encaixam e onde os blobs realmente ficam.',
      title_en: 'A Practical Guide to Active Storage',
      intro_en: 'Uploads, variants and direct uploads can feel like magic until they break. ' \
                "Here's how the pieces fit together and where the blobs actually live." },
    { title: 'Projetando com Mobile First',
      intro: 'A maioria dos leitores chega pelo celular, então a tela pequena é o design de verdade. ' \
             'Comece estreito e deixe o layout respirar conforme a viewport cresce.',
      title_en: 'Designing for Mobile First',
      intro_en: 'Most readers arrive on a phone, so the small screen is the real design. ' \
                'Start narrow, then let the layout breathe as the viewport grows.' },
    { title: 'Dicas de Postgres que Todo Dev Deveria Saber',
      intro: 'Alguns hábitos de Postgres se pagam já no primeiro dia. ' \
             'Índices, chaves UUID e defaults sensatos lideram a lista.',
      title_en: 'Postgres Tips Every Developer Should Know',
      intro_en: 'A handful of Postgres habits pay for themselves on day one. ' \
                'Indexes, UUID keys and sensible defaults top the list.' },
    { title: 'A Arte de Escrever Migrações Limpas',
      intro: 'Migrações são histórico somente-adição, então reversibilidade importa. ' \
             'Mudanças pequenas e focadas mantêm o schema legível daqui a um ano.',
      title_en: 'The Art of Writing Clean Migrations',
      intro_en: 'Migrations are append-only history, so reversibility matters. ' \
                'Small, focused changes keep the schema readable a year from now.' },
    { title: 'Deploy em uma VPS sem Dor de Cabeça',
      intro: 'Você não precisa de uma plataforma gigante para publicar um blog. ' \
             'Uma única VPS, um proxy reverso e um script de deploy já resolvem muito.',
      title_en: 'Deploying to a VPS Without the Headache',
      intro_en: 'You do not need a sprawling platform to ship a blog. ' \
                'A single VPS, a reverse proxy and a deploy script go a long way.' },
    { title: 'Entendendo Chaves Primárias UUID',
      intro: 'Inteiros sequenciais vazam informação e colidem entre sistemas. ' \
             'UUIDs trocam um pouco de espaço por portabilidade e URLs mais seguras.',
      title_en: 'Understanding UUID Primary Keys',
      intro_en: 'Sequential integers leak information and collide across systems. ' \
                'UUIDs trade a little space for portability and safer URLs.' },
    { title: 'Testando Apps Rails com RSpec',
      intro: 'Testes rápidos e honestos são a diferença entre pavor e confiança. ' \
             'Request specs cobrem o máximo de terreno com o mínimo de esforço.',
      title_en: 'Testing Rails Apps with RSpec',
      intro_en: 'Fast, honest tests are the difference between dread and confidence. ' \
                'Request specs cover the most ground for the least effort.' },
    { title: 'Construindo um Blog do Zero',
      intro: 'Às vezes a melhor forma de aprender um framework é construir o óbvio. ' \
             'Um blog toca em models, views, uploads e rotas de uma vez só.',
      title_en: 'Building a Blog from Scratch',
      intro_en: 'Sometimes the best way to learn a framework is to build the obvious thing. ' \
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
    body_en = ActionText::Content.new("<p>#{attrs[:intro_en]}</p>")
    date = (i * 18).days.ago
    Post.create!(title: attrs[:title], body: body,
                 title_en: attrs[:title_en], body_en: body_en,
                 created_at: date, updated_at: date)
  end
end
