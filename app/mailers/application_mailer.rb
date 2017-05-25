class ApplicationMailer < ActionMailer::Base
  default from: "hunger-terminal@joshsoftware.com", reply_to: "hr@joshsoftware.com"
  layout 'mailer'
end
