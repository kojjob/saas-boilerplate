# frozen_string_literal: true

class EstimateMailer < ApplicationMailer
  helper :estimates

  def send_estimate(estimate, recipient: nil, message: nil)
    @estimate = estimate
    @client = estimate.client
    @account = estimate.account
    @custom_message = message

    # Generate PDF attachment
    pdf_result = Pdf::EstimatePdfGenerator.call(estimate: estimate)
    if pdf_result.success?
      attachments[pdf_result.data[:filename]] = {
        mime_type: "application/pdf",
        content: pdf_result.data[:pdf]
      }
    end

    mail(
      to: recipient || @client.email,
      subject: "Estimate #{@estimate.estimate_number} from #{@account.name}"
    )
  end
end
