# typed: false
# frozen_string_literal: true

require "spec_helper"
require "dependabot/dependency"
require "dependabot/dependency_file"
require "dependabot/wordpress/file_updater"
require_common_spec "file_updaters/shared_examples_for_file_updaters"

RSpec.describe Dependabot::Wordpress::FileUpdater do
  subject(:updater) do
    described_class.new(
      dependencies: [dependency],
      dependency_files: dependency_files,
      credentials: []
    )
  end

  let(:dependency_files) { [plugin_file] }

  let(:plugin_file) do
    Dependabot::DependencyFile.new(
      name: "plugins/akismet/akismet.php",
      content: fixture("plugins", "akismet", "akismet.php")
    )
  end

  let(:dependency) do
    Dependabot::Dependency.new(
      name: "akismet",
      version: "5.3.3",
      previous_version: "5.3",
      requirements: [{
        requirement: "5.3.3",
        file: "plugins/akismet/akismet.php",
        source: { type: :plugin },
        groups: [:plugins]
      }],
      previous_requirements: [{
        requirement: "5.3",
        file: "plugins/akismet/akismet.php",
        source: { type: :plugin },
        groups: [:plugins]
      }],
      package_manager: "wordpress"
    )
  end

  it_behaves_like "a dependency file updater"

  describe "#updated_dependency_files" do
    subject(:updated_files) { updater.updated_dependency_files }

    context "with a plugin file" do
      it "updates the Version header" do
        expect(updated_files.length).to eq(1)
        expect(updated_files.first.content).to include("Version: 5.3.3")
        expect(updated_files.first.content).not_to include("Version: 5.3\n")
      end

      it "preserves other headers" do
        content = updated_files.first.content
        expect(content).to include("Plugin Name: Akismet Anti-Spam")
        expect(content).to include("Requires at least: 5.8")
        expect(content).to include("Requires PHP: 5.6.20")
      end
    end

    context "with a theme file" do
      let(:theme_file) do
        Dependabot::DependencyFile.new(
          name: "themes/developer-starter/style.css",
          content: fixture("themes", "developer-starter", "style.css")
        )
      end
      let(:dependency_files) { [theme_file] }
      let(:dependency) do
        Dependabot::Dependency.new(
          name: "developer-starter",
          version: "2.2.0",
          previous_version: "2.1.0",
          requirements: [{
            requirement: "2.2.0",
            file: "themes/developer-starter/style.css",
            source: { type: :theme },
            groups: [:themes]
          }],
          previous_requirements: [{
            requirement: "2.1.0",
            file: "themes/developer-starter/style.css",
            source: { type: :theme },
            groups: [:themes]
          }],
          package_manager: "wordpress"
        )
      end

      it "updates the Version header" do
        expect(updated_files.length).to eq(1)
        expect(updated_files.first.content).to include("Version: 2.2.0")
        expect(updated_files.first.content).not_to include("Version: 2.1.0")
      end

      it "preserves other headers" do
        content = updated_files.first.content
        expect(content).to include("Theme Name: Developer Starter")
        expect(content).to include("Requires at least: 6.0")
      end
    end
  end

  private

  def fixture(*path)
    File.read(File.join("spec/dependabot/wordpress/fixtures", *path))
  end
end
