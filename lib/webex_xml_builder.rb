
module Webex_xml_builder

  def xml_meetings(configuration, operation, value=nil, email=nil)
    builder = Nokogiri::XML::Builder.new { |xml|
      xml.element('xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance", 'xmlns:serv' => 'http://www.webex.com/schemas/2002/06/service') do
        xml.header{
          xml.securityContext{
            xml.webExID configuration[:webex_id]
            xml.password configuration[:password]
            xml.siteID configuration[:site_id]
            xml.partnerID configuration[:partner_id]
            xml.email email unless email == nil
          }
        }
        
        body_parsing(xml,operation,value)
      end
    }
    xml_new = builder.to_xml.gsub("element", "serv:message")
    puts xml_new
    return xml_new
  end


  def body_parsing(xml, operation, value)
    xml.body{
      case operation
      when "List Meeting"
        list_meeting_body(xml)
      when "Create Meeting"
        create_meeting_body(xml, value)
      when "Delete Meeting"
        delete_meeting_body(xml, value)
      when "List Training"
        list_training_body(xml)
      when "Delete Training"
        delete_training_body(xml, value)
      when "List Attendee"
        xml.bodyContent('xsi:type' => "java:com.webex.service.binding.attendee.LstMeetingAttendee") do
          xml.meetingKey "#{value}"
        end
      when "Invite Meeting"
        #invite_meeting_url(xml,value)
       @name=value[:name]
       @meeting_id=value[:meeting_id]
        xml.bodyContent('xsi:type' => "java:com.webex.service.binding.meeting.GetjoinurlMeeting")do
          xml.sessionKey @meeting_id
          xml.attendeeName @name
        end
      when "Create Attendee"
        create_meeting_attendee(xml,value)
      when "Join Meeting Url"
        xml.bodyContent('xsi:type' => "java:com.webex.service.binding.meeting.GetjoinurlMeeting", 'xmlns:meet' => "http://www.webex.com/schemas/2002/06/service/meeting") do
          xml.sessionKey "#{value}"
        end
      when "Host Meeting Url"
        xml.bodyContent('xsi:type' => "java:com.webex.service.binding.meeting.GethosturlMeeting", 'xmlns:meet' => "http://www.webex.com/schemas/2002/06/service/meeting") do
          xml.sessionKey "#{value}"
        end
      end
    }
  end

  def invite_meeting_url(xml,val)
    value_invite_meeting(val)
    xml.bodyContent('xsi:type' => "java:com.webex.service.binding.meeting.GetjoinurlMeeting"){
      xml.sessionKey @meeting_id
      xml.attendeeName @name
    }
  end

  def value_invite_meeting(m_data)
    @meeting_id = m_data[:meeting_id]
    @name=m_data[:name]
    puts @name
  end
  
  def body_create_meeting(m_data)  
    @start_date = "#{ m_data["month"]}/#{m_data["day"]}/#{m_data["year"]} #{m_data["hour"]}:#{m_data["minute"]}:10"
    @password = m_data["password"]
    @meet_name = m_data["topic"]
    @meet_telephone = m_data["telephone"]
    @meet_call_out = m_data["callout"]
    @meet_list_flag = m_data["flag"]
    @meet_duration = m_data["duration"]
    @attendee = m_data["attendee"]
    @attendee_list = @attendee.split(',')
  end

  def body_create_attendee(data)
    @name=data[:name]
    @email=data[:email]
    @meeting_id=data[:meeting_id]
  end

  def list_meeting_body(xml)
    xml.bodyContent('xsi:type' => "java:com.webex.service.binding.meeting.LstsummaryMeeting", 'xmlns:meet' => "http://www.webex.com/schemas/2002/06/service/meeting"){
      xml.listControl{
        xml.startFrom
        xml.maximumNum "10"
      }
      xml.order{
        xml.orderBy "STARTTIME"
      }
      xml.dateScope
    }
  end

  def list_attendee(xml,val)
    xml.bodyContent('xsi:type' => "java:com.webex.service.binding.attendee.LstMeetingAttendee"){
      xml.meetingKey val
    }

  end

  def create_meeting_attendee(xml,val)
    body_create_attendee(val)
    xml.bodyContent('xsi:type' => "java:com.webex.service.binding.attendee.CreateMeetingAttendee") do
      xml.person{
        xml.name @name
        xml.address{
          xml.addressType "PERSONAL"
        }
        xml.email @email
        #xml.type "VISITOR"

      }
      xml.role "ATTENDEE"
      xml.sessionKey @meeting_id
    end

  end


  def create_meeting_body(xml, value)
    body_create_meeting(value)
    xml.bodyContent('xsi:type' => "java:com.webex.service.binding.meeting.CreateMeeting", 'xmlns:meet' => "http://www.webex.com/schemas/2002/06/service/meeting") do
      xml.accessControl{
        xml.meetingPassword @password
      }
      xml.metaData{
        xml.confName @meet_name
        xml.meetingType "105"
        xml.agenda "Test"
      }
      xml.participants{
        xml.maxUserNumber "10"
        xml.attendees{
          for ema in @attendee_list

            xml.attendee{
              xml.person{
                #                  xml.name "test"
                xml.email ema
              }
              xml.emailInvitations true
              xml.timeZoneID "4"
            }

          end

        }
      }
      xml.enableOptions{
        xml.chat "true"
        xml.poll "true"
        xml.audioVideo "true"
        xml.attendeeList true
      }
      xml.schedule{
        xml.startDate @start_date
        xml.openTime "900"
        xml.joinTeleconfBeforeHost "true"
        xml.duration @meet_duration
        xml.timeZoneID "4"
      }
      xml.telephony{
        xml.telephonySupport "CALLIN"
        xml.extTelephonyDescription	"Call 1-800-555-1234, Passcode 98765"
      }

    end
  end



  def delete_meeting_body(xml, value)
    xml.bodyContent('xsi:type' => "java:com.webex.service.binding.meeting.DelMeeting", 'xmlns:meet' => "http://www.webex.com/schemas/2002/06/service/meeting") do
      xml.meetingKey "#{value}"
    end
  end

  def list_training_body(xml)
    xml.bodyContent('xsi:type' => "java:com.webex.service.binding.training.LstsummaryTrainingSession", 'xmlns:meet' => "http://www.webex.com/schemas/2002/06/service/meeting") do
      xml.listControl{
        xml.startFrom "1"
        xml.maximumNum "10"
      }
      xml.order{
        xml.orderBy "STARTTIME"
      }
      xml.dateScope
    end
  end

  def delete_training_body(xml, value)
    xml.bodyContent('xsi:type' => "java:com.webex.service.binding.training.DelTrainingSession",'xmlns:meet' => "http://www.webex.com/schemas/2002/06/service/meeting") do
      xml.sessionKey "#{value}"
    end
  end
end