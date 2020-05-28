# frozen_string_literal: true

module Thredded
  class PostModerationRecordPolicy
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def history?
      true
    end
  end
end
