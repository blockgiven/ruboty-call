module Ruboty
  module Handlers
    class Call < Base
      env :TWILIO_ACCOUNT_SID, 'twilio account sid'
      env :TWILIO_AUTH_TOKEN, 'twilio auth token'
      env :TWILIO_DISABLE_RECORD, 'Pass 1 to disable recording (default: nil)'
      env :RUBOTY_PHONE_NUMBER, 'twilio phone number'
      env :RUBOTY_LANG, 'which language ruboty speaks. details: https://jp.twilio.com/docs/api/twiml/say#attributes-language', optional: true

      on /call \+(?<to>\d+) (?<text>.*)/, name: 'phone_call', description: "make a call, and record #{Ruboty::Call::Actions::Call::MAX_RECORDING_TIME}sec"

      # call is already used in ruboty
      def phone_call(message)
        Ruboty::Call::Actions::Call.new(message).call
      end
    end
  end
end
