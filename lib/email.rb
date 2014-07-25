# encoding: UTF-8
require 'net/smtp'

require_relative "../config/settings"

class Email
  include TorqueBox::Messaging::Backgroundable

  FROM = Settings::EMAIL
  FROM_ALIAS = "Bokanbefalinger/Deichmanske bibliotek"

  always_background :new_user

   def self.new_password(email, password)

   msg = <<END_OF_MESSAGE
Content-type: text/plain; charset=UTF-8
From: #{FROM_ALIAS} <#{FROM}>
To: <#{email}>
Subject: anbefalinger.deichman.no: nytt passord

Hei,

Det har blitt laget et nytt passord for din konto: #{password}
Du bør bytte passord når du logger deg på.

Du logger inn på http://anbefalinger.deichman.no for å bidra med anbefalinger.

Brukernavn er e-postadressen din.

Beste hilsen,
Bokanbefalingsteamet
END_OF_MESSAGE

    smtp = Net::SMTP.new('smtp.gmail.com', 587)
    smtp.enable_starttls
    smtp.start("gmail.com", Settings::EMAIL, Settings::EMAIL_PASS, :login) do
      smtp.send_message msg, FROM, email
    end

  end
end