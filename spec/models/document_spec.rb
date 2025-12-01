# frozen_string_literal: true

require "rails_helper"

RSpec.describe Document, type: :model do
  describe "associations" do
    it "belongs to account" do
      association = described_class.reflect_on_association(:account)
      expect(association.macro).to eq :belongs_to
    end

    it "belongs to project optionally" do
      association = described_class.reflect_on_association(:project)
      expect(association.macro).to eq :belongs_to
      expect(association.options[:optional]).to be true
    end

    it "belongs to uploaded_by (User)" do
      association = described_class.reflect_on_association(:uploaded_by)
      expect(association.macro).to eq :belongs_to
      expect(association.options[:class_name]).to eq "User"
    end

    it "has one attached file" do
      expect(Document.new.file).to be_an_instance_of(ActiveStorage::Attached::One)
    end
  end

  describe "validations" do
    subject { build(:document) }

    it { should validate_presence_of(:name) }

    describe "file validations" do
      it "accepts valid file types" do
        document = build(:document, :with_pdf)
        expect(document).to be_valid
      end

      it "accepts image files" do
        document = build(:document, :with_image)
        expect(document).to be_valid
      end

      it "rejects files over 25MB" do
        document = build(:document)
        # Attach a file that's too large
        large_file = StringIO.new("x" * 26.megabytes)
        document.file.attach(
          io: large_file,
          filename: "large_file.pdf",
          content_type: "application/pdf"
        )

        expect(document).not_to be_valid
        expect(document.errors[:file]).to include("is too big (maximum is 25MB)")
      end

      it "rejects invalid file types" do
        document = build(:document)
        document.file.attach(
          io: StringIO.new("test content"),
          filename: "test.exe",
          content_type: "application/x-msdownload"
        )

        expect(document).not_to be_valid
        expect(document.errors[:file]).to include("must be an image, PDF, document, or spreadsheet")
      end
    end
  end

  describe "enums" do
    it "defines category enum" do
      expect(Document.categories).to eq({
        "general" => 0,
        "contract" => 1,
        "proposal" => 2,
        "receipt" => 3,
        "photo" => 4,
        "permit" => 5,
        "insurance" => 6,
        "other" => 7
      })
    end
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let(:user) do
      u = create(:user)
      create(:membership, user: u, account: account, role: :owner)
      u
    end

    describe ".recent" do
      it "orders by created_at descending" do
        old_doc = create(:document, account: account, uploaded_by: user, created_at: 2.days.ago)
        new_doc = create(:document, account: account, uploaded_by: user, created_at: 1.hour.ago)

        expect(Document.recent.first).to eq(new_doc)
        expect(Document.recent.last).to eq(old_doc)
      end
    end

    describe ".search" do
      it "finds documents by name" do
        doc = create(:document, account: account, uploaded_by: user, name: "Project Contract")
        expect(Document.search("Contract")).to include(doc)
      end

      it "finds documents by description" do
        doc = create(:document, account: account, uploaded_by: user, description: "Main construction permit")
        expect(Document.search("permit")).to include(doc)
      end

      it "returns all when query is blank" do
        doc = create(:document, account: account, uploaded_by: user)
        expect(Document.search("")).to include(doc)
        expect(Document.search(nil)).to include(doc)
      end
    end
  end

  describe "instance methods" do
    let(:document) { create(:document, :with_pdf) }

    describe "#file_type" do
      it "returns content type when file is attached" do
        expect(document.file_type).to eq("application/pdf")
      end

      it "returns nil when no file is attached" do
        doc_without_file = create(:document)
        expect(doc_without_file.file_type).to be_nil
      end
    end

    describe "#file_size" do
      it "returns byte size when file is attached" do
        expect(document.file_size).to be > 0
      end

      it "returns nil when no file is attached" do
        doc_without_file = create(:document)
        expect(doc_without_file.file_size).to be_nil
      end
    end

    describe "#image?" do
      it "returns true for image files" do
        image_doc = create(:document, :with_image)
        expect(image_doc.image?).to be true
      end

      it "returns false for non-image files" do
        expect(document.image?).to be false
      end

      it "returns false when no file is attached" do
        doc_without_file = create(:document)
        expect(doc_without_file.image?).to be false
      end
    end

    describe "#pdf?" do
      it "returns true for PDF files" do
        expect(document.pdf?).to be true
      end

      it "returns false for non-PDF files" do
        image_doc = create(:document, :with_image)
        expect(image_doc.pdf?).to be false
      end

      it "returns false when no file is attached" do
        doc_without_file = create(:document)
        expect(doc_without_file.pdf?).to be false
      end
    end
  end
end
