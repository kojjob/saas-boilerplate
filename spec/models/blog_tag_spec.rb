require 'rails_helper'

RSpec.describe BlogTag, type: :model do
  describe 'associations' do
    it { should have_many(:blog_post_tags).dependent(:destroy) }
    it { should have_many(:blog_posts).through(:blog_post_tags) }
  end

  describe 'validations' do
    subject { build(:blog_tag) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(50) }

    # Slug uniqueness tested with custom validation since it's auto-generated
    it 'validates uniqueness of slug' do
      create(:blog_tag, slug: 'test-slug')
      tag = build(:blog_tag, slug: 'test-slug')
      expect(tag).not_to be_valid
      expect(tag.errors[:slug]).to include('has already been taken')
    end

    it 'validates uniqueness of name' do
      create(:blog_tag, name: 'Ruby')
      tag = build(:blog_tag, name: 'Ruby')
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include('has already been taken')
    end
  end

  describe 'slug generation' do
    it 'auto-generates slug from name if not provided' do
      tag = create(:blog_tag, name: 'Ruby on Rails', slug: nil)
      expect(tag.slug).to eq('ruby-on-rails')
    end

    it 'preserves custom slug if provided' do
      tag = create(:blog_tag, name: 'Rails', slug: 'ruby-rails')
      expect(tag.slug).to eq('ruby-rails')
    end

    it 'handles special characters' do
      tag = create(:blog_tag, name: 'C++ Programming', slug: nil)
      expect(tag.slug).to eq('c-programming')
    end
  end

  describe 'scopes' do
    describe '.popular' do
      it 'orders by posts_count descending' do
        low = create(:blog_tag, posts_count: 5)
        high = create(:blog_tag, posts_count: 20)
        medium = create(:blog_tag, posts_count: 10)

        expect(BlogTag.popular.first).to eq(high)
        expect(BlogTag.popular.last).to eq(low)
      end
    end

    describe '.alphabetical' do
      it 'orders by name' do
        z_tag = create(:blog_tag, name: 'Zebra')
        a_tag = create(:blog_tag, name: 'Apple')

        expect(BlogTag.alphabetical.first).to eq(a_tag)
      end
    end

    describe '.with_posts' do
      it 'returns tags that have posts' do
        tag_with_posts = create(:blog_tag, posts_count: 5)
        tag_without_posts = create(:blog_tag, posts_count: 0)

        expect(BlogTag.with_posts).to include(tag_with_posts)
        expect(BlogTag.with_posts).not_to include(tag_without_posts)
      end
    end
  end

  describe '#to_param' do
    it 'returns the slug for URL generation' do
      tag = build(:blog_tag, slug: 'ruby-tips')
      expect(tag.to_param).to eq('ruby-tips')
    end
  end
end
