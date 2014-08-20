require 'openssl'

class Api::Private::EmailRepliesController < Api::ApiController
  before_filter :require_mailgun_origin, only:   :reply
  before_filter :require_login,          except: :reply
  protect_from_forgery                   except: :reply
  skip_authorization_check               only:   :reply

  # Mailgun will POST to this endpoint when someone replies to an
  # email with a reply-to of the form:
  #
  #     reply-(reply_info)@mail.community.hackerschool.com
  #
  # important params:
  #
  #     reply_info, a Base64 encoded and signed string that can be
  #       verified with ReplyInfoVerifier.verify
  #     stripped-text, the plain-text email body, not including a
  #       signature or trailing quoted text
  #     timestamp, token, signature, used to verify that the POST
  #       originated from Mailgun: concat timestamp and token,
  #       encode with HMAC using Mailgun API key as the key and
  #       SHA256 digest mode, compare result to signature
  #
  # Mailgun expects a 200 for success for a 406 for not acceptable.
  # For any other code, Mailgun will retry the POST on an increasing
  # interval over the next 8 hours.
  def reply
    unless valid_reply_info?
      head 406 and return
    end

    post = thread.posts.build

    unless can?(:create, post)
      head 406 and return
    end

    post.author = current_user
    post.body = params['stripped-text']

    unless post.save
      head 406 and return
    end

    PubSub.publish :created, :post, post

    # TODO: parse and notify @mentions as well
    ThreadSubscriptionNotifier.new(post).notify

    head 200
  end

private
  def reply_info
    @reply_info ||= begin
      ReplyInfoVerifier.verify(params['reply_info'])
    rescue ReplyInfoVerifier::InvalidSignature => e
      nil
    end
  end

  def valid_reply_info?
    !reply_info.nil?
  end

  def current_user
    reply_info[0]
  end

  def thread
    reply_info[1]
  end

  def require_mailgun_origin
    api_key = ENV["MAILGUN_API_KEY"]
    digest = OpenSSL::Digest::SHA256.new
    data = "#{params[:timestamp]}#{params[:token]}"

    unless SecureEquals.secure_equals(params[:signature], OpenSSL::HMAC.hexdigest(digest, api_key, data))
      head 404
    end
  end
end