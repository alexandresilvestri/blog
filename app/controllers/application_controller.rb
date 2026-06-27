class ApplicationController < ActionController::Base
  include Authentication

  around_action :switch_locale

  private

  def switch_locale(&action)
    locale = params[:locale] || session[:locale] || I18n.default_locale
    locale = I18n.default_locale unless I18n.available_locales.map(&:to_s).include?(locale.to_s)
    session[:locale] = locale
    I18n.with_locale(locale, &action)
  end
end
