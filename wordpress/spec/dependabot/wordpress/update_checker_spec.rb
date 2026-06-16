# typed: false
# frozen_string_literal: true

require "spec_helper"
require "dependabot/dependency"
require "dependabot/dependency_file"
require "dependabot/wordpress/update_checker"
require_common_spec "update_checkers/shared_examples_for_update_checkers"

RSpec.describe Dependabot::Wordpress::UpdateChecker do
  let(:checker) do
    described_class.new(
      dependency: dependency,
      dependency_files: dependency_files,
      credentials: credentials
    )
  end

  let(:credentials) do
    [{
      "type" => "git_source",
      "host" => "github.com",
      "username" => "x-access-token",
      "password" => "token"
    }]
  end

  let(:dependency_files) { [] }

  let(:dependency) do
    Dependabot::Dependency.new(
      name: "akismet",
      version: "5.3",
      requirements: [{
        requirement: "5.3",
        file: "plugins/akismet/akismet.php",
        source: { type: :plugin },
        groups: [:plugins]
      }],
      package_manager: "wordpress"
    )
  end

  it_behaves_like "an update checker"

  describe "#latest_version" do
    subject { checker.latest_version }

    context "when the plugin exists on wordpress.org" do
      before do
        stub_request(
          :get,
          "https://api.wordpress.org/plugins/info/1.2/" \
          "?action=plugin_information&request[slug]=akismet&request[fields][versions]=1"
        ).to_return(
          status: 200,
          body: fixture("api_responses", "akismet_plugin_info.json")
        )
      end

      it "returns the latest version" do
        expect(subject).to eq(Dependabot::Wordpress::Version.new("5.3.3"))
      end
    end

    context "when the plugin is not found" do
      before do
        stub_request(
          :get,
          "https://api.wordpress.org/plugins/info/1.2/" \
          "?action=plugin_information&request[slug]=akismet&request[fields][versions]=1"
        ).to_return(
          status: 200,
          body: fixture("api_responses", "not_found.json")
        )
      end

      it { is_expected.to be_nil }
    end

    context "when the API returns an error" do
      before do
        stub_request(
          :get,
          "https://api.wordpress.org/plugins/info/1.2/" \
          "?action=plugin_information&request[slug]=akismet&request[fields][versions]=1"
        ).to_return(status: 500)
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#latest_version for a theme" do
    let(:dependency) do
      Dependabot::Dependency.new(
        name: "developer-starter",
        version: "2.1.0",
        requirements: [{
          requirement: "2.1.0",
          file: "themes/developer-starter/style.css",
          source: { type: :theme },
          groups: [:themes]
        }],
        package_manager: "wordpress"
      )
    end

    before do
      stub_request(
        :get,
        "https://api.wordpress.org/themes/info/1.2/" \
        "?action=theme_information&request[slug]=developer-starter&request[fields][versions]=1"
      ).to_return(
        status: 200,
        body: fixture("api_responses", "developer_starter_theme_info.json")
      )
    end

    it "returns the latest theme version" do
      expect(checker.latest_version).to eq(Dependabot::Wordpress::Version.new("2.2.0"))
    end
  end

  describe "#latest_resolvable_version" do
    before do
      stub_request(
        :get,
        "https://api.wordpress.org/plugins/info/1.2/" \
        "?action=plugin_information&request[slug]=akismet&request[fields][versions]=1"
      ).to_return(
        status: 200,
        body: fixture("api_responses", "akismet_plugin_info.json")
      )
    end

    it "returns the same as latest_version" do
      expect(checker.latest_resolvable_version).to eq(checker.latest_version)
    end
  end

  describe "#latest_resolvable_version_with_no_unlock" do
    it "returns the current version" do
      expect(checker.latest_resolvable_version_with_no_unlock).to eq("5.3")
    end
  end

  describe "#updated_requirements" do
    before do
      stub_request(
        :get,
        "https://api.wordpress.org/plugins/info/1.2/" \
        "?action=plugin_information&request[slug]=akismet&request[fields][versions]=1"
      ).to_return(
        status: 200,
        body: fixture("api_responses", "akismet_plugin_info.json")
      )
    end

    it "returns updated requirements with new version" do
      expect(checker.updated_requirements).to eq([{
        requirement: "5.3.3",
        file: "plugins/akismet/akismet.php",
        source: { type: :plugin },
        groups: [:plugins]
      }])
    end
  end

  private

  def fixture(*path)
    File.read(File.join("spec/dependabot/wordpress/fixtures", *path))
  end
end
