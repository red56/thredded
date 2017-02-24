# frozen_string_literal: true
module Thredded
  # A view model for Topic.
  class TopicView < Thredded::BaseTopicView
    delegate :categories, :id, :blocked?, :last_moderation_record, :followers,
             :last_post, :messageboard_id, :messageboard_name,
             to: :@topic

    # @param topic [TopicCommon]
    # @param read_state [UserTopicReadStateCommon, nil]
    # @param policy [#destroy?]
    def initialize(topic, read_state, follow, policy)
      super(topic, read_state, policy)
      @follow = follow
    end

    def self.from_user(topic, user)
      read_state = follow = nil
      if user && !user.thredded_anonymous?
        read_state = Thredded::UserTopicReadState.find_by(user_id: user.id, postable_id: topic.id)
        follow = Thredded::UserTopicFollow.find_by(user_id: user.id, topic_id: topic.id)
      end
      new(topic, read_state, follow, Pundit.policy!(user, topic))
    end

    def states
      super + [
        (:locked if @topic.locked?),
        (:sticky if @topic.sticky?),
        (@follow ? :following : :notfollowing)
      ].compact
    end

    # @return [Boolean] whether the topic is followed by the current user.
    def followed?
      @follow
    end

    def follow_reason
      @follow.try(:reason)
    end

    def can_moderate?
      @policy.moderate?
    end

    def path
      if @topic.first_unread_post
        anchor = "post_#{@topic.first_unread_post.id}"
      else
        anchor = "post_#{@topic.last_post.id}" if @topic.last_post
      end
      Thredded::UrlsHelper.topic_path(@topic, page: @read_state.page, anchor: anchor)
    end

    def edit_path
      Thredded::UrlsHelper.edit_messageboard_topic_path(@topic.messageboard, @topic)
    end

    def destroy_path
      Thredded::UrlsHelper.messageboard_topic_path(@topic.messageboard, @topic)
    end

    def follow_path
      Thredded::UrlsHelper.follow_messageboard_topic_path(@topic.messageboard, @topic)
    end

    def unfollow_path
      Thredded::UrlsHelper.unfollow_messageboard_topic_path(@topic.messageboard, @topic)
    end

    def messageboard_path
      Thredded::UrlsHelper.messageboard_topics_path(@topic.messageboard)
    end

    def new_post_preview_path
      Thredded::UrlsHelper.preview_new_messageboard_topic_post_path(@topic.messageboard, @topic)
    end
  end
end
