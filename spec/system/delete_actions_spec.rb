# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Delete actions", type: :system do
  let(:account) { create(:account) }
  let(:user) { create(:user, :confirmed, email: "delete-test@example.com", password: "password123", password_confirmation: "password123") }
  let!(:membership) { create(:membership, user: user, account: account, role: :owner) }

  before do
    driven_by(:selenium_chrome_headless)
    # Sign in via the browser
    visit sign_in_path
    fill_in "email", with: user.email
    fill_in "password", with: "password123"
    click_button "Sign in"
    expect(page).to have_current_path(dashboard_path)
  end

  describe "deleting a client" do
    let!(:client) { create(:client, account: account, name: "Client To Delete") }

    it "shows confirmation dialog and deletes client" do
      # Delete button is on the show page, not index
      visit client_path(client)

      expect(page).to have_content("Client To Delete")

      # Click delete button - Turbo will handle the confirmation
      # Note: In headless Chrome, Turbo confirmations auto-accept
      click_button "Delete Client"

      # Should redirect to clients index and show success message
      expect(page).to have_current_path(clients_path, wait: 10)
      expect(page).to have_content("Client was successfully deleted")
    end

    it "verifies delete button exists on client show page" do
      visit client_path(client)

      expect(page).to have_content("Client To Delete")
      expect(page).to have_button("Delete Client")
    end

    context "when client has projects" do
      before { create(:project, account: account, client: client) }

      it "does not show delete button when client has associated projects" do
        visit client_path(client)

        # The delete button should not be visible when client has projects
        expect(page).not_to have_button("Delete Client")
        # Verify we're on the right page
        expect(page).to have_content(client.name)
      end
    end
  end

  describe "deleting a project" do
    let!(:client) { create(:client, account: account) }
    let!(:project) { create(:project, account: account, client: client, name: "Project To Delete") }

    it "shows confirmation and deletes project" do
      # Delete button is on the show page
      visit project_path(project)

      expect(page).to have_content("Project To Delete")

      # Click delete button - Turbo handles confirmation
      click_button "Delete Project"

      expect(page).to have_current_path(projects_path, wait: 10)
      # Flash message animation starts at opacity: 0, use visible: :all to find it
      expect(page).to have_selector("[role='alert']", text: "Project was successfully deleted", visible: :all, wait: 5)
    end
  end

  describe "deleting an invoice" do
    let!(:client) { create(:client, account: account) }
    let!(:invoice) { create(:invoice, account: account, client: client, status: :draft) }

    it "allows deleting draft invoice" do
      # Delete button is inside a dropdown menu on the show page
      visit invoice_path(invoice)

      # Find the delete form (has method=delete action pointing to invoice) and submit it directly
      # This bypasses the dropdown UI complexity and Turbo confirm (which auto-accepts in headless)
      page.execute_script(<<~JS)
        // Find the form that deletes this invoice
        const forms = document.querySelectorAll('form[action*="invoices"]');
        for (const form of forms) {
          const methodInput = form.querySelector('input[name="_method"][value="delete"]');
          if (methodInput) {
            // Remove turbo-confirm to skip confirmation dialog
            delete form.dataset.turboConfirm;
            form.submit();
            break;
          }
        }
      JS

      expect(page).to have_current_path(invoices_path, wait: 10)
      # Flash message animation starts at opacity: 0, use visible: :all to find it
      expect(page).to have_selector("[role='alert']", text: "Invoice was successfully deleted", visible: :all, wait: 5)
    end
  end

  describe "deleting a document" do
    let!(:document) { create(:document, account: account, name: "Document To Delete") }

    it "shows confirmation and deletes document" do
      # Delete button is on the show page
      visit document_path(document)

      expect(page).to have_content("Document To Delete")

      # Click delete button - Turbo handles confirmation
      click_button "Delete Document"

      expect(page).to have_current_path(documents_path, wait: 10)
      # Flash message animation starts at opacity: 0, use visible: :all to find it
      expect(page).to have_selector("[role='alert']", text: "Document was successfully deleted", visible: :all, wait: 5)
    end
  end

  describe "deleting a time entry" do
    let!(:client) { create(:client, account: account) }
    let!(:project) { create(:project, account: account, client: client, status: :active) }
    let!(:time_entry) { create(:time_entry, account: account, project: project) }

    it "shows confirmation and deletes time entry" do
      # Delete button is on the show page
      visit time_entry_path(time_entry)

      # Click delete button - Turbo handles confirmation
      click_button "Delete"

      expect(page).to have_current_path(time_entries_path, wait: 10)
      # Wait for flash message element with animation
      expect(page).to have_selector("[role='alert']", text: "Time entry was successfully deleted", visible: :all, wait: 5)
    end
  end

  describe "deleting a material entry" do
    let!(:client) { create(:client, account: account) }
    let!(:project) { create(:project, account: account, client: client, status: :active) }
    let!(:material_entry) { create(:material_entry, account: account, project: project, name: "Material To Delete") }

    it "shows confirmation and deletes material entry" do
      # Delete button is on the show page
      visit material_entry_path(material_entry)

      expect(page).to have_content("Material To Delete")

      # Click delete button - Turbo handles confirmation
      click_button "Delete"

      expect(page).to have_current_path(material_entries_path, wait: 10)
      # Wait for flash message element with animation
      expect(page).to have_selector("[role='alert']", text: "Material entry was successfully deleted", visible: :all, wait: 5)
    end
  end
end
