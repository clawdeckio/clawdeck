class PagesController < ApplicationController
  allow_unauthenticated_access
  redirect_authenticated_users
  layout "landing"
  def home
  end
end
