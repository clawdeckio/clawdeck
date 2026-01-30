class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create verify ]
  redirect_authenticated_users only: %i[ new verify ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }
  layout "auth", only: %i[ new verify ]

  def new
  end

  # Step 1: Request verification code
  def create
    email = params.permit(:email_address)[:email_address]
    user = User.find_or_create_by(email_address: email)
    user.generate_verification_code
    VerificationCodeMailer.send_code(user).deliver_later

    redirect_to verify_session_path(email: email), notice: "Check your email for a verification code."
  end

  # Step 2: Verify code and log in
  def verify
    @email = params[:email]

    if request.post?
      user = User.find_by(email_address: params[:email])
      if user&.verify_code(params[:code])
        user.clear_verification_code
        start_new_session_for user
        redirect_to after_authentication_url, notice: "Welcome back!"
      else
        redirect_to verify_session_path(email: params[:email]), alert: "Invalid or expired code. Please try again."
      end
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, status: :see_other
  end
end
