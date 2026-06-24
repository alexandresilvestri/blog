class SessionMailer < ApplicationMailer
  def magic_link(user)
    @user = user
    @url = verify_session_url(token: user.generate_token_for(:magic_link))
    mail(to: user.email, subject: 'Your sign-in link')
  end
end
