class AgentsController < ApplicationController
  before_action :set_agent, only: [:show]

  def index
    @agents = current_user.agents.order(last_heartbeat_at: :desc)
  end

  def show
    @commands = @agent.agent_commands.order(created_at: :desc).limit(20)
    @tasks_assigned = @agent.assigned_tasks.order(updated_at: :desc).limit(10)
    @tasks_claimed = @agent.claimed_tasks.order(updated_at: :desc).limit(10)
  end

  private

  def set_agent
    @agent = current_user.agents.find(params[:id])
  end
end
