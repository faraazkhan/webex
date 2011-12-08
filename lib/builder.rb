require 'rubygems'
require 'nokogiri'
require 'net/https'
require 'rexml/document'

class Webex
  include Webex_xml_builder
  include Xml_parse
  attr_accessor :webex_id,:password,:site_id,:partner_id

  def initialize
    webex_yaml_file = "#{RAILS_ROOT}/config/webex.yml"
    @raw_webex_configuration = {}
    return false unless File.exist?(webex_yaml_file)
    @raw_webex_configuration = YAML.load(ERB.new(File.read(webex_yaml_file)).result)
    if defined? RAILS_ENV
      @raw_webex_configuration = @raw_webex_configuration[RAILS_ENV]
    end
    Thread.current[:webex_api_config] = @raw_webex_configuration unless Thread.current[:webex_api_config]

    apply_configuration(@raw_webex_configuration)
  end

  def apply_configuration(config)
    @configuraion = Hash.new
    @configuration = {
      :webex_id   => config['webex_id'],
      :password   => config['password'],
      :site_id    => config['site_id'],
      :partner_id => config['partner_id'],
      :host       => config['host']}
  end

  def authenticate(value, back_url)
    uri = URI.parse("https://apidemoeu.webex.com/apidemoeu/p.php?AT=LI&WID=#{value[:webexid]}&PW=#{value[:password]}&MU=#{back_url}")
    return uri
  end
  
  def list_meetings(operation_name = "List Meeting")
    xml_value= xml_meetings(@configuration, operation_name)
    res = Net::HTTP.start(@configuration[:host]){ |http|
      http.post("/WBXService/XMLService",xml_value)
    }
    xml_data = res.body
    meeting_data = Hash.new
    m_list = List.new
    meeting_data= m_list.parse_xml(res.body)
    puts res.body
    return meeting_data
  end

  def get_invite_meeting_url(meeting_data)
    @data = meeting_data
    operation_name="Invite Meeting"
    xml_value= xml_meetings(@configuration, operation_name, @data)
    res = Net::HTTP.start(@configuration[:host]){ |http|
      http.post("/WBXService/XMLService",xml_value)
    }
    xml_data = res.body
    doc = REXML::Document.new xml_data
    invite_url=doc.root.elements["serv:body"].elements[1].elements["meet:inviteMeetingURL"].text
    
  end


  def create_meeting(meeting_data, operation_name = "Create Meeting")
    @m_data = meeting_data
    xml_value = xml_meetings(@configuration, operation_name, @m_data)
    res = Net::HTTP.start(@configuration[:host]){ |http|
      http.post("/WBXService/XMLService",xml_value)
    }    
    xml_data = res.body
    response = Hash.new
    doc = REXML::Document.new xml_data
    header = doc.root.elements["serv:header"].elements["serv:response"]
    response= {:result => header.elements["serv:result"].text}
    if response[:result] == "FAILURE"
      response= {:reason => header.elements["serv:reason"].text}
    else     
      body = doc.root.elements["serv:body"].elements[1]
      url = body.elements["meet:iCalendarURL"]
      response = {:meeting_key => body.elements["meet:meetingkey"].text,        
        :host => url.elements["serv:host"].text,
        :attendee => url.elements["serv:attendee"].text,
        :guset_token => body.elements["meet:guestToken"].text}
    end
    return response
  end

  #list all meeting attendee
  def list_meeting_attendee(meeting_id=nil)
    operation_name="List Attendee"
    @id = meeting_id unless meeting_id.nil?
    xml_value= xml_meetings(@configuration, operation_name,@id)
    
    res = Net::HTTP.start(@configuration[:host]){ |http|
      http.post("/WBXService/XMLService",xml_value)
    }
    xml_data = res.body
    meeting_data = Hash.new
    attend = Attendee.new
    meeting_data= attend.parse_xml(res.body)
    puts res.body
    return meeting_data
  end

  #create meeting attendee
  def create_attendee(meeting_data)
    operation_name = "Create Attendee"
    @m_data = meeting_data
    xml_value = xml_meetings(@configuration, operation_name, @m_data)
    res = Net::HTTP.start(@configuration[:host]){ |http|
      http.post("/WBXService/XMLService",xml_value)
    }
    xml_data = res.body
    puts xml_data
    return xml_data
  end



  #to delete a meeting using meeting_key
  def delete_meeting(meeting_key, operation_name = "Delete Meeting")
    value = meeting_key
    xml_value = xml_meetings(@configuration, operation_name,value)
    res = Net::HTTP.start(@configuration[:host]){ |http|
      http.post("/WBXService/XMLService",xml_value)
    }
    xml_data = res.body
    response = Hash.new
    doc = REXML::Document.new xml_data
    header = doc.root.elements["serv:header"].elements["serv:response"]
    response= {:result => header.elements["serv:result"].text}
    return response
  end

  def list_training(operation_name = "List Training")
    xml_value= xml_meetings(@configuration, operation_name)
    res = Net::HTTP.start(@configuration[:host]){ |http|
      http.post("/WBXService/XMLService",xml_value)
    }
    xml_data = res.body
    t_list = Tlist.new
    meeting_data = t_list.parse_xml(xml_data)
    return meeting_data
  end

  def del_training(id,operation_name = "Delete Training")
    xml_value = xml_meetings(@configuration, operation_name,id)
    res = Net::HTTP.start(@configuration[:host]){ |http|
      http.post("/WBXService/XMLService",xml_value)
    }
    t_list = Tlist.new
    response = t_list.delete_response(res.body)
    return response
  end

  def create_user(user, url)
    back_url = "https://#{@configuration[:host]}/#{@configuration[:host].split(".").first}/p.php?AT=SU&FN=#{user.first_name}&LN=#{user.last_name}&EM=#{user.email}&WID=#{user.webex_id}&PW=#{user.password}&&PID=g0webx!&BU=#{url}"
    return back_url
  end

  def login_user(url)
    url = "https://#{@configuration[:host]}/#{@configuration[:host].split(".").first}/p.php?AT=LI&WID=#{@configuration[:webex_id]}&PW=#{@configuration[:password]}&MU=#{url}"
    return url
  end

  def get_meeting_url(value, operation_name = "Join Meeting Url")
    xml_value = xml_meetings(@configuration, operation_name,value)
    res = Net::HTTP.start(@configuration[:host]){ |http|
      http.post("/WBXService/XMLService",xml_value)
    }
    xml_data = res.body
    t_list = Tlist.new
    meeting_data = t_list.get_join_url(xml_data)
    return meeting_data
  end

  def host_meeting_url(value, operation_name = "Host Meeting Url")
    xml_value = xml_meetings(@configuration, operation_name,value)
    res = Net::HTTP.start(@configuration[:host]){ |http|
      http.post("/WBXService/XMLService",xml_value)
    }
    xml_data = res.body
    t_list = Tlist.new
    meeting_data = t_list.get_host_url(xml_data)
    return meeting_data
  end


  class List
    attr_accessor :id ,:type, :host, :timezone, :status,:startdate,:startdate,:duration,:lsistStatus,
      :hostJoined, :participants, :topic
    def parse_xml(res_xml)
      doc = REXML::Document.new res_xml
      main_element = doc.root.elements["serv:body"].elements[1]
      a = Array.new
      main_element.elements.delete main_element.elements["meet:matchingRecords"]
      main_element.each{|element|
        @m_list = List.new
        unless (element.elements["meet:meetingKey"].nil?  || element.elements["meet:confName"].text.nil?  || element.elements["meet:meetingType"].text.nil? || element.elements["meet:hostWebExID"].text.nil? ||  element.elements["meet:timeZone"].text.nil? || element.elements["meet:status"].text.nil? || element.elements["meet:status"].text.nil? || element.elements["meet:startDate"].text.nil? || element.elements["meet:duration"].text.nil? ||element.elements["meet:listStatus"].text.nil? || element.elements["meet:hostJoined"].text.nil? || element.elements["meet:participantsJoined"].text.nil?)

          @m_list.id = element.elements["meet:meetingKey"].text
          @m_list.topic = element.elements["meet:confName"].text
          @m_list.host = element.elements["meet:hostWebExID"].text
          @m_list.timezone = element.elements["meet:timeZone"].text
          @m_list.status = element.elements["meet:status"].text
          @m_list.startdate = element.elements["meet:startDate"].text
          @m_list.duration = element.elements["meet:duration"].text
          @m_list.lsistStatus = element.elements["meet:listStatus"].text
          @m_list.hostJoined = element.elements["meet:hostJoined"].text
          @m_list.participants = element.elements["meet:participantsJoined"].text
        end

        a << @m_list
      }
      return a;

    end

  end

  class Attendee
    attr_accessor :email, :attendee_id, :name, :phone,:attendee_type, :accepted,:time_zone,:join_status,:language,:locale,:conf_id
    def parse_xml(res_xml)
      doc = REXML::Document.new res_xml
      main_element = doc.root.elements["serv:body"].elements[1]
      arr = Array.new
      main_element.elements.delete main_element.elements[1]
      
      main_element.each {|element|
        @attendee = Attendee.new
        @attendee.email = element.elements[1].elements["com:email"].text unless element.elements[1].elements["com:email"].nil?
        @attendee.name = element.elements[1].elements["com:name"].text unless element.elements[1].elements["com:name"].nil?
        #@attendee.attendee_type = element.elements[1].elements["com:type"].text
        #@attendee.phone = element.elements[1].elements["com:phones"].text
        @attendee.attendee_id = element.elements["att:attendeeId"].text
        @attendee.attendee_type = element.elements["att:person"].elements["com:type"].text unless element.elements["att:person"].elements["com:type"].nil?
        @attendee.phone = element.elements["att:person"].elements["com:phones"].text unless  element.elements["att:person"].elements["com:phones"].nil? || element.elements["att:person"].elements["com:phones"].text.nil?
        @attendee.conf_id = element.elements["att:confID"].text unless element.elements["att:confID"].nil? || element.elements["att:confID"].text.nil?
        @attendee.accepted= element.elements["att:status"].elements["att:accepted"].text unless element.elements["att:status"].elements["att:accepted"].nil? || element.elements["att:status"].elements["att:accepted"].text.nil?
        @attendee.language = element.elements["att:language"].text unless element.elements["att:language"].nil? || element.elements["att:language"].text.nil?
        @attendee.locale = element.elements["att:locale"].text unless element.elements["att:locale"].nil? || element.elements["att:locale"].text.nil?
        @attendee.time_zone = element.elements["att:timeZoneID"].text unless element.elements["att:timeZoneID"].nil? || element.elements["att:timeZoneID"].text.nil?
        @attendee.join_status = element.elements["att:joinStatus"].text unless element.elements["att:joinStatus"].nil? || element.elements["att:joinStatus"].text.nil?

        puts @attendee.email
        puts @attendee.name
        
        arr << @attendee

      }
      return arr;
    end
  end

end
