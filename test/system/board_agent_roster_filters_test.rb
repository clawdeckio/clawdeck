require "application_system_test_case"

class BoardAgentRosterFiltersTest < ApplicationSystemTestCase
  test "agent roster filters agents by inferred state buckets" do
    user = users(:one)
    board = boards(:one)

    working_agent = agents(:two)
    working_agent.update!(
      name: "Working Agent",
      status: "syncing",
      last_seen_at: 30.seconds.ago
    )

    idle_agent = agents(:one)
    idle_agent.update!(
      name: "Idle Agent",
      status: "standing_by",
      last_seen_at: 5.minutes.ago
    )

    offline_agent = user.agents.create!(
      name: "Offline Agent",
      status: "paused",
      identifier: "agent-three",
      last_seen_at: 30.minutes.ago
    )

    sign_in_via_form_for_board!(user, board)

    assert_current_path board_path(board), ignore_query: true

    roster = find("[data-controller~='agent-roster']", wait: 10)
    within roster do
      find("button[title='Agent roster']", wait: 10).click
      body = find("[data-agent-roster-target='body']", wait: 10)

      within body do
        assert_text working_agent.name, wait: 10
        assert_text idle_agent.name, wait: 10
        assert_text offline_agent.name, wait: 10
      end
    end

    assert_roster_filter(roster, "all", show: [ working_agent.name, idle_agent.name, offline_agent.name ], hide: [])
    assert_roster_filter(roster, "working", show: [ working_agent.name ], hide: [ idle_agent.name, offline_agent.name ])
    assert_roster_filter(roster, "idle", show: [ idle_agent.name ], hide: [ working_agent.name, offline_agent.name ])
    assert_roster_filter(roster, "offline", show: [ offline_agent.name ], hide: [ working_agent.name, idle_agent.name ])
  end

  private

  def assert_roster_filter(roster, filter, show:, hide:)
    within roster do
      find("button[data-agent-roster-filter-param='#{filter}']", wait: 10).click
      body = find("[data-agent-roster-target='body']", wait: 10)

      within body do
        show.each { |name| assert_text name, wait: 10 }
        hide.each { |name| assert_no_text name, wait: 10 }
      end
    end
  end

  def sign_in_via_form_for_board!(user, board)
    visit board_path(board)
    assert_current_path new_session_path, ignore_query: true

    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
  end
end
