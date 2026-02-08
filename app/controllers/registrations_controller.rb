class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  redirect_authenticated_users only: %i[new create]
  layout "auth"

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url, notice: "Welcome to PokéDeck!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
