require 'rails_helper'

RSpec.describe BlogCategory, type: :model do
  describe 'associations' do
    it { should have_many(:blog_posts).dependent(:nullify) }
    it { should belong_to(:parent).class_name('BlogCategory').optional }
    it { should have_many(:children).class_name('BlogCategory').with_foreign_key(:parent_id).dependent(:nullify) }
  end

  describe 'validations' do
    subject { build(:blog_category) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }
    it { should validate_length_of(:meta_title).is_at_most(70) }
    it { should validate_length_of(:meta_description).is_at_most(160) }

    # Slug uniqueness tested with custom validation since it's auto-generated
    it 'validates uniqueness of slug' do
      create(:blog_category, slug: 'test-slug')
      category = build(:blog_category, slug: 'test-slug')
      expect(category).not_to be_valid
      expect(category.errors[:slug]).to include('has already been taken')
    end
  end

  describe 'slug generation' do
    it 'auto-generates slug from name if not provided' do
      category = create(:blog_category, name: 'Web Development Tips', slug: nil)
      expect(category.slug).to eq('web-development-tips')
    end

    it 'preserves custom slug if provided' do
      category = create(:blog_category, name: 'Web Development', slug: 'custom-slug')
      expect(category.slug).to eq('custom-slug')
    end

    it 'sanitizes slug to be URL-friendly' do
      category = create(:blog_category, name: 'Tips & Tricks!', slug: nil)
      expect(category.slug).to eq('tips-tricks')
    end
  end

  describe 'scopes' do
    let!(:parent) { create(:blog_category, name: 'Parent') }
    let!(:child) { create(:blog_category, name: 'Child', parent: parent) }
    let!(:root) { create(:blog_category, name: 'Root', parent_id: nil) }

    describe '.roots' do
      it 'returns categories without parent' do
        expect(BlogCategory.roots).to include(parent, root)
        expect(BlogCategory.roots).not_to include(child)
      end
    end

    describe '.ordered' do
      it 'orders by position then name' do
        BlogCategory.destroy_all
        cat_a = create(:blog_category, name: 'AAA', position: 2)
        cat_b = create(:blog_category, name: 'BBB', position: 1)
        expect(BlogCategory.ordered.first).to eq(cat_b)
      end
    end
  end

  describe 'hierarchy' do
    let(:parent) { create(:blog_category, name: 'Programming') }
    let(:child) { create(:blog_category, name: 'Ruby', parent: parent) }

    it 'allows nested categories' do
      expect(child.parent).to eq(parent)
      expect(parent.children).to include(child)
    end

    it 'knows if it has children' do
      child # trigger creation
      expect(parent.has_children?).to be true
      expect(child.has_children?).to be false
    end
  end

  describe '#meta_title_or_name' do
    it 'returns meta_title when present' do
      category = build(:blog_category, name: 'Test', meta_title: 'SEO Title')
      expect(category.meta_title_or_name).to eq('SEO Title')
    end

    it 'falls back to name when meta_title is blank' do
      category = build(:blog_category, name: 'Test', meta_title: nil)
      expect(category.meta_title_or_name).to eq('Test')
    end
  end
end
