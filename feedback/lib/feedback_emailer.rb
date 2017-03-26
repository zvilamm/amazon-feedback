require 'csv'
require 'erb'
require 'net/smtp'
require 'tlsmail'
require 'YAML'

#First we assign the global variables for the sender account, password, subject and email body
#user_info = File.readlines “config.txt”
  config = File.open("config.yaml") { |config_file| YAML.load(config_file) }
  @company = config['company']
  @sender = config['sender']
  @subject = config['subject']
  @email_account = config['account']
  @password = config['password']
  @order_file = config['order_file']

  template_letter = File.read "feedback.erb"
  erb_template = ERB.new template_letter

#We  need to create the email (From, To, Subject, Body)
def create_email( to, from, subject, body)
#The following lines should not be indented!!
result = <<EOF
From: #{from}
To: #{to}
Subject: #{subject}
 
#{body}
EOF
 result
end

#This is the method that actually sends the email.
def send_email(from, to, message, smtp)
  smtp.send_message(message, @email_account, to)
end	

#this method will wrap it all up.
def get_feedback(customer_email, message, smtp)
    #it called the method 'send_email' for that address
   send_email(@email_account, customer_email, (create_email(customer_email, @email_account, @subject, message)), smtp)
end

#run through the spreadsheet and get feedback!
begin
  Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
  Net::SMTP.start('smtp.gmail.com', '587', 'gmail.com', @email_account, @password, :plain) do |smtp|
    contents = CSV.open @order_file, headers: true
    contents.each do |row|
      order = row['order-id']
      product = row['product-name']
      date = row['purchase-date'].slice(5, 5)
      name = row['buyer-name']
      email = row['buyer-email']
      personalized = erb_template.result(binding)
      get_feedback(email, personalized, smtp)
    end
  end
end



