require 'rexml/document'

module Xml_parse
  
  class Tlist
    attr_accessor :id ,:type, :host, :timezone,:status,:startdate,:duration,:lsistStatus,
      :hostJoined, :participants, :topic, :otherhost, :total
    def parse_xml(res_xml)

      doc = REXML::Document.new res_xml
      main_element = doc.root.elements["serv:body"]
      @main_element = main_element.elements[1]
      a = Array.new
      @main_element.each{|element|
        @t_list = Tlist.new
        unless (element.elements["train:sessionKey"].nil? || element.elements["train:confName"].nil? || element.elements["train:meetingType"].nil? || element.elements["train:hostWebExID"].nil? || element.elements["train:listStatus"].nil? || element.elements["train:duration"].nil? || element.elements["train:startDate"].nil? ||element.elements["train:timeZone"].nil? || element.elements["train:status"].nil?
          )
          @t_list.id = element.elements[1].text
          @t_list.topic = element.elements["train:confName"].text 
          @t_list.type = element.elements["train:meetingType"].text
          @t_list.host = element.elements["train:hostWebExID"].text
          @t_list.otherhost = element.elements["train:otherHostWebExID"].text if !element.elements["train:otherHostWebExID"].blank?
          @t_list.timezone = element.elements["train:timeZone"].text
          @t_list.status = element.elements["train:status"].text
          @t_list.startdate = element.elements["train:startDate"].text
          @t_list.duration = element.elements["train:duration"].text
          @t_list.lsistStatus = element.elements["train:listStatus"].text          
        end
        a << @t_list
      }

      return a;

    end

    def delete_response(xml)
      res = Hash.new
      doc = REXML::Document.new xml
      header = doc.root.elements["serv:header"].elements["serv:response"]
      res = {:result => header.elements["serv:result"].text}
      return res
    end

    def get_join_url(xml)
      res = Hash.new
      doc = REXML::Document.new xml
      header = doc.root.elements["serv:header"].elements["serv:response"]
      res = {:result => header.elements["serv:result"].text}
      if res[:result] == 'SUCCESS'
        main_element = doc.root.elements["serv:body"]
        element = main_element.elements[1].elements["meet:joinMeetingURL"].text
        return element
      else
        return res
      end
    end

    def get_host_url(xml)
      res = Hash.new
      doc = REXML::Document.new xml
      header = doc.root.elements["serv:header"].elements["serv:response"]
      res = {:result => header.elements["serv:result"].text}
      if res[:result] == 'SUCCESS'
        main_element = doc.root.elements["serv:body"]
        element = main_element.elements[1].elements["meet:hostMeetingURL"].text
        return element
      else
        return res
      end
    end
  end


end