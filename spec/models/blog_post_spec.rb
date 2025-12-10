require 'rails_helper'

RSpec.describe BlogPost, type: :model do
  describe 'associations' do
    it { should belong_to(:author).class_name('User') }
    it { should belong_to(:blog_category).optional.counter_cache(:posts_count) }
    it { should have_many(:blog_post_tags).dependent(:destroy) }
    it { should have_many(:blog_tags).through(:blog_post_tags) }
  end

  describe 'validations' do
    subject { build(:blog_post) }

    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:title).is_at_most(200) }
    it { should validate_length_of(:meta_title).is_at_most(70) }
    it { should validate_length_of(:meta_description).is_at_most(160) }
    it { should validate_length_of(:excerpt).is_at_most(500) }

    # Slug uniqueness tested with custom validation since it's auto-generated
    it 'validates uniqueness of slug' do
      create(:blog_post, slug: 'test-post-slug')
      post = build(:blog_post, slug: 'test-post-slug')
      expect(post).not_to be_valid
      expect(post.errors[:slug]).to include('has already been taken')
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(draft: 0, published: 1, scheduled: 2, archived: 3) }
  end

  describe 'slug generation' do
    it 'auto-generates slug from title if not provided' do
      post = create(:blog_post, title: 'How to Build a SaaS App', slug: nil)
      expect(post.slug).to eq('how-to-build-a-saas-app')
    end

    it 'preserves custom slug if provided' do
      post = create(:blog_post, title: 'My Post', slug: 'custom-url-slug')
      expect(post.slug).to eq('custom-url-slug')
    end

    it 'ensures unique slug by appending number' do
      create(:blog_post, title: 'Test Post', slug: 'test-post')
      post2 = create(:blog_post, title: 'Test Post', slug: nil)
      expect(post2.slug).to match(/test-post-\d+/)
    end
  end

  describe 'reading time calculation' do
    it 'calculates reading time based on content length' do
      content = 'word ' * 500 # 500 words
      post = create(:blog_post, content: content)
      expect(post.reading_time).to eq(3) # ceil(500/200) = 3 minutes
    end

    it 'returns minimum of 1 minute for short content' do
      post = create(:blog_post, content: 'Short post')
      expect(post.reading_time).to eq(1)
    end
  end

  describe 'scopes' do
    let!(:published_post) { create(:blog_post, :published) }
    let!(:draft_post) { create(:blog_post, :draft) }
    let!(:scheduled_post) { create(:blog_post, :scheduled) }
    let!(:featured_post) { create(:blog_post, :published, featured: true) }

    describe '.published' do
      it 'returns only published posts' do
        expect(BlogPost.published).to include(published_post, featured_post)
        expect(BlogPost.published).not_to include(draft_post, scheduled_post)
      end
    end

    describe '.draft' do
      it 'returns only draft posts' do
        expect(BlogPost.draft).to include(draft_post)
        expect(BlogPost.draft).not_to include(published_post)
      end
    end

    describe '.featured' do
      it 'returns featured posts' do
        expect(BlogPost.featured).to include(featured_post)
        expect(BlogPost.featured).not_to include(published_post)
      end
    end

    describe '.recent' do
      it 'orders by published_at descending' do
        BlogPost.destroy_all
        old_post = create(:blog_post, :published, published_at: 1.week.ago)
        new_post = create(:blog_post, :published, published_at: 1.hour.ago)

        expect(BlogPost.recent.first).to eq(new_post)
      end
    end

    describe '.by_category' do
      it 'filters by category' do
        category = create(:blog_category)
        post_in_category = create(:blog_post, blog_category: category)
        post_without_category = create(:blog_post)

        expect(BlogPost.by_category(category.id)).to include(post_in_category)
        expect(BlogPost.by_category(category.id)).not_to include(post_without_category)
      end
    end

    describe '.by_tag' do
      it 'filters by tag' do
        tag = create(:blog_tag)
        post_with_tag = create(:blog_post)
        post_with_tag.blog_tags << tag
        post_without_tag = create(:blog_post)

        expect(BlogPost.by_tag(tag.id)).to include(post_with_tag)
        expect(BlogPost.by_tag(tag.id)).not_to include(post_without_tag)
      end
    end

    describe '.search' do
      it 'searches in title and content' do
        matching_title = create(:blog_post, title: 'Ruby on Rails Guide')
        matching_content = create(:blog_post, content: 'Learn Ruby programming')
        non_matching = create(:blog_post, title: 'Python Tips', content: 'Python guide')

        results = BlogPost.search('Ruby')
        expect(results).to include(matching_title, matching_content)
        expect(results).not_to include(non_matching)
      end
    end
  end

  describe '#publish!' do
    let(:post) { create(:blog_post, :draft) }

    it 'changes status to published' do
      post.publish!
      expect(post).to be_published
    end

    it 'sets published_at timestamp' do
      freeze_time do
        post.publish!
        expect(post.published_at).to eq(Time.current)
      end
    end
  end

  describe '#unpublish!' do
    let(:post) { create(:blog_post, :published) }

    it 'changes status to draft' do
      post.unpublish!
      expect(post).to be_draft
    end
  end

  describe '#increment_views!' do
    let(:post) { create(:blog_post, views_count: 10) }

    it 'increments views_count' do
      expect { post.increment_views! }.to change { post.reload.views_count }.from(10).to(11)
    end
  end

  describe '#meta_title_or_title' do
    it 'returns meta_title when present' do
      post = build(:blog_post, title: 'Original', meta_title: 'SEO Optimized Title')
      expect(post.meta_title_or_title).to eq('SEO Optimized Title')
    end

    it 'falls back to title when meta_title is blank' do
      post = build(:blog_post, title: 'Original Title', meta_title: nil)
      expect(post.meta_title_or_title).to eq('Original Title')
    end
  end

  describe '#excerpt_or_truncated_content' do
    it 'returns excerpt when present' do
      post = build(:blog_post, excerpt: 'Custom excerpt', content: 'Long content...')
      expect(post.excerpt_or_truncated_content).to eq('Custom excerpt')
    end

    it 'returns truncated content when excerpt is blank' do
      long_content = 'A' * 200
      post = build(:blog_post, excerpt: nil, content: long_content)
      expect(post.excerpt_or_truncated_content.length).to be <= 160
    end
  end

  describe '#to_param' do
    it 'returns the slug for URL generation' do
      post = build(:blog_post, slug: 'my-awesome-post')
      expect(post.to_param).to eq('my-awesome-post')
    end
  end

  describe '#previous_post' do
    it 'returns the previous published post' do
      old_post = create(:blog_post, :published, published_at: 2.days.ago)
      current_post = create(:blog_post, :published, published_at: 1.day.ago)

      expect(current_post.previous_post).to eq(old_post)
    end
  end

  describe '#next_post' do
    it 'returns the next published post' do
      current_post = create(:blog_post, :published, published_at: 2.days.ago)
      newer_post = create(:blog_post, :published, published_at: 1.day.ago)

      expect(current_post.next_post).to eq(newer_post)
    end
  end
end
