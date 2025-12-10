require 'rails_helper'

RSpec.describe BlogPostTag, type: :model do
  describe 'associations' do
    it { should belong_to(:blog_post) }
    it { should belong_to(:blog_tag).counter_cache(:posts_count) }
  end

  describe 'validations' do
    it 'validates uniqueness of blog_post_id scoped to blog_tag_id' do
      post = create(:blog_post)
      tag = create(:blog_tag)
      create(:blog_post_tag, blog_post: post, blog_tag: tag)

      duplicate = build(:blog_post_tag, blog_post: post, blog_tag: tag)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:blog_post_id]).to include('has already been taken')
    end
  end

  describe 'counter cache' do
    let(:tag) { create(:blog_tag, posts_count: 0) }
    let(:post) { create(:blog_post) }

    it 'increments tag posts_count when created' do
      expect { create(:blog_post_tag, blog_post: post, blog_tag: tag) }
        .to change { tag.reload.posts_count }.by(1)
    end

    it 'decrements tag posts_count when destroyed' do
      post_tag = create(:blog_post_tag, blog_post: post, blog_tag: tag)
      expect { post_tag.destroy }
        .to change { tag.reload.posts_count }.by(-1)
    end
  end
end
