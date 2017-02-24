# frozen_string_literal: true
require 'spec_helper'

module Thredded
  describe TopicView, '#css_class' do
    let(:user) { build_stubbed(:user) }

    it 'builds a class with locked if the topic is locked' do
      topic = build_stubbed(:topic, locked: true)
      topic_view = TopicView.from_user(topic, create(:user))

      expect(topic_view.states).to include :locked
    end

    it 'builds a class with sticky if the topic is sticky' do
      topic = build_stubbed(:topic, sticky: true)
      topic_view = TopicView.from_user(topic, create(:user))

      expect(topic_view.states).to include :sticky
    end

    it 'returns nothing if plain vanilla topic' do
      topic = build_stubbed(:topic)
      topic_view = TopicView.from_user(topic, create(:user))

      expect(topic_view.states).not_to include(:locked, :sticky)
    end

    it 'returns string with several topic states' do
      topic = build_stubbed(:topic, sticky: true, locked: true)
      topic_view = TopicView.from_user(topic, create(:user))

      expect(topic_view.states).to include(:locked, :sticky)
    end
  end

  describe TopicView, '#read?' do
    it 'is true if the posts counts match' do
      topic = create(:topic, with_posts: 2)
      user = create(:user)
      create(
        :user_topic_read_state,
        postable: topic,
        user: user,
        read_at: topic.updated_at
      )
      topic_view = TopicView.from_user(topic, user)

      expect(topic_view.read?).to eq true
    end

    it 'is false if the posts counts match' do
      topic = create(:topic, with_posts: 4)
      user = create(:user)
      create(
        :user_topic_read_state,
        postable: topic,
        user: user,
        read_at: topic.first_post.updated_at - 1.day
      )
      topic_view = TopicView.from_user(topic, user)

      expect(topic_view.read?).to eq false
    end

    it 'is false if we have a null user' do
      topic = create(:topic, with_posts: 2)
      user = nil
      topic_view = TopicView.from_user(topic, user)

      expect(topic_view.read?).to eq false
    end
  end

  describe TopicView, '#states' do
    it 'prepends a read state' do
      topic = create(:topic, :locked, :sticky, with_posts: 2)
      user = create(:user)
      create(
        :user_topic_read_state,
        postable: topic,
        user: user,
        read_at: topic.last_post.updated_at,
        page: 4
      )
      topic_view = TopicView.from_user(topic, user)
      expect(topic_view.states[0]).to eq :read
    end

    it 'prepends an unread state' do
      topic = create(:topic, :locked, :sticky, with_posts: 2)
      user = create(:user)
      create(
        :user_topic_read_state,
        postable: topic,
        user: user,
        read_at: topic.first_post.updated_at - 1.day,
        page: 4
      )
      topic_view = TopicView.from_user(topic, user)
      expect(topic_view.states[0]).to eq :unread
    end
    it 'includes a following state' do
      topic = create(:topic, :locked, :sticky, with_posts: 2)
      user = create(:user)
      create(:user_topic_follow, topic: topic, user: user)
      topic_view = TopicView.from_user(topic, user)
      expect(topic_view.states).to include(:following)
    end

    it 'includes an notfollowing state' do
      topic = create(:topic, :locked, :sticky, with_posts: 2)
      user = create(:user)
      topic_view = TopicView.from_user(topic, user)
      expect(topic_view.states).to include :notfollowing
    end
  end

  describe TopicView, '#path' do
    let(:user) { create(:user) }
    let(:messageboard) { create(:messageboard) }
    let(:topic) do
      create(:topic, messageboard: messageboard)
    end
    subject { TopicView.from_user(topic, create(:user)) }

    context 'with an unviewed topic' do
      it 'returns topic path' do
        expect(subject.path).to eq "/thredded/#{topic.messageboard.slug}/#{topic.slug}"
      end
    end

    context 'with a viewed topic' do
      let(:post) {create(:post, postable: topic)}
      let(:unread_post) {create(:post, postable: topic)}
      let(:read_state) { create(:user_topic_read_state, postable: topic, user: user, read_at: post.created_at) }
      before { allow(unread_post).to receive(:mark_as_unread).and_return(post) }
      it 'returns topic path' do
        expect(subject.path).to end_with("#post_#{post.id}")
      end
    end

    context 'with a post marked as unread' do
      let(:first_post) {create(:post, postable: topic)}
      let(:second_post) {create(:post, postable: topic)}
      let(:third_post) { create(:post, postable: topic) }

      before do
        travel_to 2.days.ago do
          first_post
        end
        travel_to 1.day.ago do
          second_post
        end
        travel_to 1.minute.ago do
          third_post
          second_post.mark_as_unread(user, 1)
        end
      end

      it 'returns topic path' do
        expect(subject.path).to end_with("#post_#{second_post.id}")
      end
    end
  end
end
