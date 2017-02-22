# frozen_string_literal: true
require 'spec_helper'

module Thredded
  describe UserDetail, 'counter caching' do
    it 'bumps the posts count when a new post is created' do
      user = create(:user)
      user_details = create(:user_detail, user: user)
      create(:post, user: user)

      expect(user_details.reload.posts_count).to eq(1)
    end

    it 'bumps the topics count when a new topic is created' do
      user = create(:user)
      user_details = create(:user_detail, user: user)
      create(:topic, user: user)

      expect(user_details.reload.topics_count).to eq(1)
    end
  end

  describe UserDetail, 'destroying' do
    let!(:post) { create(:post, user: user_detail.user) }
    let(:user) { create(:user) }
    let(:user_detail) { create(:user_detail, user: user) }

    it "destroying user doesn't delete user's posts but nulls them" do
      expect { user.destroy }.not_to change { Thredded::Post.count }
      expect(post.reload.user).to eq(nil)
      expect(post.reload.user_id).to eq(nil)
    end

    it "destroying user deletes user's user detail" do
      expect { user.destroy }.to change { Thredded::UserDetail.count }.by(-1)
    end

    it "destroying user detail doesn't delete user's posts" do
      expect { user_detail.destroy }.not_to change { Thredded::Post.count }
    end

    describe 'also checking deletion' do
      it "deleting user detail doesn't delete user's posts" do
        expect { user.delete }.not_to change { Thredded::Post.count }
      end

      it "deleting user detail doesn't delete user's posts" do
        expect { user.delete }.not_to change { Thredded::Post.count }
      end
    end
  end
end
