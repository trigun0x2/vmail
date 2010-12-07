require 'mail'
require 'open3'

class MessageFormatter
  # initialize with a Mail object
  def initialize(mail, uid = nil)
    @mail = mail
    @uid = uid
  end

  def list_parts(parts = (@mail.parts.empty? ? [@mail] : @mail.parts))
    if parts.empty?
      return nil
    end
    lines = parts.map do |part|
      if part.multipart?
        list_parts(part.parts)
      else
        # part.charset could be used
        "- #{part.content_type}"
      end
    end
    lines.join("\n")
  end

  def process_body
    part = find_text_part(@mail.parts)
    if part
      if part.header["Content-Type"].to_s =~ /text\/plain/
        format_text_body(part.body) 
      elsif part.header["Content-Type"].to_s =~ /text\/html/
        format_html_body(part.body) 
      else
        format_text_body(part.body) 
      end
    else 
      "NO BODY" 
    end
  end

  def find_text_part(parts = @mail.parts)
    if parts.empty?
      return @mail
    end

    part = parts.detect {|part| part.multipart?}
    if part
      find_text_part(part.parts)
    else
      part = parts.detect {|part| (part.header["Content-Type"].to_s =~ /text\/plain/) }
      if part
        return part
      else
        return "no text part"
      end
    end
  end

  def format_text_body(body)
    body.decoded.gsub("\r", '')
  end

  # depend on lynx
  def format_html_body(body)
    stdin, stdout, stderr = Open3.popen3("lynx -stdin -dump")
    stdin.puts(body.decoded)
    stdin.close
    stdout.read
  end

  def extract_headers(mail = @mail)
    headers = {'from' => mail['from'].decoded,
      'date' => mail.date,
      'to' => mail['to'].nil? ? nil : mail['to'].decoded,
      'subject' => mail.subject
    }
    if !mail.cc.nil?
      headers['cc'] = mail['cc'].decoded.to_s
    end
    if !mail.reply_to.nil?
      headers['reply_to'] = mail['reply_to'].decoded
    end
    headers
  end

  def encoding
    @mail.encoding
  end
end