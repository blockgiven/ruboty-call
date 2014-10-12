require 'twilio-ruby'
require 'uri'

module Ruboty
  module Call
    module Actions
      class Call < Ruboty::Actions::Base
        STATUS_REFRESH_INTERVAL = 5
        MAX_RECORDING_TIME = 20

        def call
          phone_call
        end

        private

        def from
          ENV['RUBOTY_PHONE_NUMBER']
        end

        def language
          ENV['RUBOTY_LANG'] || 'ja-JP'
        end

        def max_recording_time
          MAX_RECORDING_TIME
        end

        def phone_call
          c = twilio_client.account.calls.create({
            :to => to,
            :from => from,
            :url => twiml_url,
            :method => 'GET',
            :fallback_method => 'GET',
            :status_callback_method => 'GET',
            :record => 'true'
          })

          loop do
            sleep STATUS_REFRESH_INTERVAL

            c.refresh

            if %w(queued ringing in-progress).include?(c.status)
              next message.reply(status_text[c.status])
            end

            message.reply(status_text[c.status])
            recs = c.recordings.list
            if recs.size.nonzero?
              urls = recs.map {|r| "https://api.twilio.com#{r.uri.gsub(/.json$/, '.mp3')}" }
              message.reply("おへんじ:#{$/}#{urls.join($/)}")
            end
            break
          end
        rescue
          message.reply("なにかに失敗したよ.")
        end

        def text
          message[:text]
        end

        def to
          message[:to]
        end

        def status_text
          {
            'queued' => '通話は発信待ち状態です。',
            'ringing' => '呼び出し中です。',
            'in-progress' => '相手が応答し、通話中です。',
            'canceled' => 'queued または ringing 中に、通話がキャンセルされました。',
            'completed' => '相手が応答し、通話が正常に終了しました。',
            'busy' => '相手からビジー信号を受信しました。',
            'failed' => '通話を接続できませんでした。通常は、ダイヤルした電話番号が存在しません。',
            'no-answer' => '相手が応答せず、通話が終了しました。'
          }
        end

        def twilio_client
          # put your own credentials here
          account_sid = ENV['TWILIO_ACCOUNT_SID']
          auth_token = ENV['TWILIO_AUTH_TOKEN']

          Twilio::REST::Client.new account_sid, auth_token
        end

        def twiml
          <<TWIML
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice" language="#{language}">#{text}</Say>
    <Record maxLength="#{max_recording_time}" />
</Response>
TWIML
        end

        def twiml_url
          "http://twimlets.com/echo?Twiml=#{URI.escape(twiml)}"
        end
      end
    end
  end
end
