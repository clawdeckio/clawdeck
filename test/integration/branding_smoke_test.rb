require "test_helper"
require "fileutils"
require "open3"
require "securerandom"

class BrandingSmokeTest < ActionDispatch::IntegrationTest
  test "public pages use PokéDeck branding (no ClawDeck remnants)" do
    # Home page
    get root_path
    assert_response :success

    assert_includes @response.body, "PokéDeck"
    assert_not_includes @response.body, "ClawDeck"
    assert_not_includes @response.body, "Claw Deck"
    assert_includes @response.body, "github.com/clawdeckio/pokedeck"
    assert_not_includes @response.body, "github.com/clawdeckio/clawdeck"

    # PWA manifest (served as JSON via /manifest.json)
    get "/manifest.json"
    assert_response :success

    assert_includes @response.body, "PokéDeck"
    assert_not_includes @response.body, "ClawDeck"
    assert_not_includes @response.body, "Claw Deck"
  end

  test "branding guardrail scans frontend and mailers" do
    token = SecureRandom.hex(6)
    js_path = Rails.root.join("app/javascript/branding_guardrail_#{token}.js")
    mailer_path = Rails.root.join("app/mailers/branding_guardrail_#{token}.rb")
    js_path_in_output = js_path.relative_path_from(Rails.root).to_s
    mailer_path_in_output = mailer_path.relative_path_from(Rails.root).to_s

    begin
      File.write(js_path, 'const guardrailBranding = "ClawDeck";')

      stdout, stderr, status = run_branding_guardrail
      assert_not status.success?, "Expected guardrail to fail for app/javascript\n#{stdout}\n#{stderr}"
      assert_includes "#{stdout}\n#{stderr}", js_path_in_output

      FileUtils.rm_f(js_path)
      File.write(mailer_path, <<~RUBY)
        class BrandingGuardrailProbeMailer < ApplicationMailer
          def ping
            mail subject: "ClawDeck"
          end
        end
      RUBY

      stdout, stderr, status = run_branding_guardrail
      assert_not status.success?, "Expected guardrail to fail for app/mailers\n#{stdout}\n#{stderr}"
      assert_includes "#{stdout}\n#{stderr}", mailer_path_in_output
    ensure
      FileUtils.rm_f(js_path)
      FileUtils.rm_f(mailer_path)
    end
  end

  test "branding guardrail ignores node_modules and tmp directories" do
    token = SecureRandom.hex(6)
    node_modules_dir = Rails.root.join("app/javascript/node_modules/branding_guardrail_#{token}")
    tmp_dir = Rails.root.join("app/javascript/tmp/branding_guardrail_#{token}")
    node_modules_path = node_modules_dir.join("probe.js")
    tmp_path = tmp_dir.join("probe.txt")

    begin
      FileUtils.mkdir_p(node_modules_dir)
      FileUtils.mkdir_p(tmp_dir)
      File.write(node_modules_path, 'const ignoredNodeModulesBranding = "ClawDeck";')
      File.write(tmp_path, "ClawDeck")

      stdout, stderr, status = run_branding_guardrail
      assert status.success?, "Expected guardrail to ignore tmp/node_modules\n#{stdout}\n#{stderr}"
    ensure
      FileUtils.rm_rf(node_modules_dir)
      FileUtils.rm_rf(tmp_dir)
    end
  end

  private

  def run_branding_guardrail
    Open3.capture3("bash", "script/check_user_facing_branding.sh", chdir: Rails.root.to_s)
  end
end
