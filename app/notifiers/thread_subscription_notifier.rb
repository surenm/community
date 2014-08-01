require 'set'

class ThreadSubscriptionNotifier < Notifier
  include RecipientVariables

  attr_reader :post

  def initialize(post)
    @post = post
  end

  def notify(email_recipients=possible_recipients)
    unless email_recipients.empty?
      BatchNotificationSender.delay.deliver(:new_post_in_subscribed_thread_email, recipient_variables(email_recipients, post.thread), email_recipients, post)
    end
  end

  def possible_recipients
    @possible_recipients ||= post.thread.subscribers.where.not(id: post.author).select { |u| Ability.new(u).can? :read, post }.to_set
  end
end
