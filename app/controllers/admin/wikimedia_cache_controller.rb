module Admin
  class WikimediaCacheController < ApplicationController
    def rebuild
      unless current_user.admin
        flash[:notice] = "You don't have permission to perform that action."
        redirect_to root_path and return
      end

      Thread.new { WikimediaCacheBuilder.rebuild }

      flash[:notice] = "Wikimedia cache rebuild started in the background."
      redirect_back(fallback_location: root_path)
    end
  end
end
