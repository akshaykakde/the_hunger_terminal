class DevelopmentMailInterceptor 
  def self.delivering_email(message)
    # message.subject = ""  
    message.to = ["akshay@joshsoftware.com, kirand@joshsoftware.com"]
  end
end