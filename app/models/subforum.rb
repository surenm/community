class Subforum < ActiveRecord::Base
  has_many :threads, class_name: 'DiscussionThread'

  has_many :visited_statuses, as: :visitable

  # we need to specify class_name because we want "thread" to be pluralized,
  # not "status".
  has_many :threads_with_visited_status, class_name: 'ThreadWithVisitedStatus'

  def threads_for_user(user)
    threads_with_visited_status.for_user(user)
  end

  def mark_unread_at(time)
    update!(marked_unread_at: time)
  end

  def mark_as_visited_for(user)
    status = visited_statuses.where(user_id: user.id).first_or_initialize
    status.update!(last_visited: DateTime.current)
  end
end
