# typed: false
# frozen_string_literal: true

require "spec_helper"
require "dependabot/dependency"
require "dependabot/wordpress/metadata_finder"
require_common_spec "metadata_finders/shared_examples_for_metadata_finders"

RSpec.describe Dependabot::Wordpress::MetadataFinder do
  subject(:finder) do
    described_class.new(
      dependency: dependency,
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

  it_behaves_like "a dependency metadata finder"

  describe "#source_url" do
    subject { finder.source_url }

    context "for a plugin without a source URL" do
      it { is_expected.to be_nil }
    end

    context "with a GitHub source URL in requirements" do
      let(:dependency) do
        Dependabot::Dependency.new(
          name: "developer-starter",
          version: "2.1.0",
          requirements: [{
            requirement: "2.1.0",
            file: "themes/developer-starter/style.css",
            source: { type: :theme, source_url: "https://github.com/developer/starter-theme" },
            groups: [:themes]
          }],
          package_manager: "wordpress"
        )
      end

      it "returns the GitHub URL" do
        expect(subject).to eq("https://github.com/developer/starter-theme")
      end
    end
  end

  describe "#homepage_url" do
    context "for a plugin" do
      it "returns the wordpress.org plugin URL" do
        expect(finder.homepage_url).to eq("https://wordpress.org/plugins/akismet/")
      end
    end

    context "for a theme" do
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

      it "returns the wordpress.org theme URL" do
        expect(finder.homepage_url).to eq("https://wordpress.org/themes/developer-starter/")
      end
    end
  end
end
