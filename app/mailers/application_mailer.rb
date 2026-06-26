class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('MAIL_FROM', 'magicLink@alexandresilvestri.com.br')
  layout 'mailer'
end
