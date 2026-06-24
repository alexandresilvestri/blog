class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('MAIL_FROM', 'noreply@alexandresilvestri.com.br')
  layout 'mailer'
end
