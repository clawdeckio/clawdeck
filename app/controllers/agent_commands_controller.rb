class AgentCommandsController < ApplicationController
  before_action :set_agent

  def create
    @command = @agent.agent_commands.build(command_params)
    @command.requested_by_user = current_user
    @command.state = :pending

    if @command.save
      redirect_to agent_path(@agent), notice: "#{@command.kind.humanize} command queued."
    else
      redirect_to agent_path(@agent), alert: "Failed to queue command: #{@command.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_agent
    @agent = current_user.agents.find(params[:agent_id])
  end

  def command_params
    params.require(:agent_command).permit(:kind, :payload)
  end
end
