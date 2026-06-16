# typed: false
# frozen_string_literal: true

require "spec_helper"
require "dependabot/dependency_file"
require "dependabot/wordpress/file_parser"
require_common_spec "file_parsers/shared_examples_for_file_parsers"

RSpec.describe Dependabot::Wordpress::FileParser do
  subject(:parser) do
    described_class.new(
      dependency_files: dependency_files,
      source: source
    )
  end

  let(:source) do
    Dependabot::Source.new(
      provider: "github",
      repo: "example/repo",
      directory: "/"
    )
  end

  let(:dependency_files) { [plugin_file] }

  let(:plugin_file) do
    Dependabot::DependencyFile.new(
      name: "plugins/akismet/akismet.php",
      content: fixture("plugins", "akismet", "akismet.php")
    )
  end

  it_behaves_like "a dependency file parser"

  describe "#parse" do
    subject(:dependencies) { parser.parse }

    context "with a plugin file" do
      let(:dependency_files) { [plugin_file] }

      it "parses the plugin dependency" do
        expect(dependencies.length).to eq(1)

        dep = dependencies.first
        expect(dep.name).to eq("akismet")
        expect(dep.version).to eq("5.3")
        expect(dep.requirements).to eq([{
          requirement: "5.3",
          file: "plugins/akismet/akismet.php",
          source: { type: :plugin },
          groups: [:plugins]
        }])
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

      it "parses the theme dependency" do
        expect(dependencies.length).to eq(1)

        dep = dependencies.first
        expect(dep.name).to eq("developer-starter")
        expect(dep.version).to eq("2.1.0")
        expect(dep.requirements).to eq([{
          requirement: "2.1.0",
          file: "themes/developer-starter/style.css",
          source: { type: :theme },
          groups: [:themes]
        }])
      end
    end

    context "with multiple files" do
      let(:hello_file) do
        Dependabot::DependencyFile.new(
          name: "plugins/hello-dolly/hello.php",
          content: fixture("plugins", "hello-dolly", "hello.php")
        )
      end
      let(:theme_file) do
        Dependabot::DependencyFile.new(
          name: "themes/developer-starter/style.css",
          content: fixture("themes", "developer-starter", "style.css")
        )
      end
      let(:dependency_files) { [plugin_file, hello_file, theme_file] }

      it "parses all dependencies" do
        expect(dependencies.length).to eq(3)
        expect(dependencies.map(&:name)).to contain_exactly("akismet", "hello-dolly", "developer-starter")
      end
    end

    context "with a custom Update URI plugin" do
      let(:custom_file) do
        Dependabot::DependencyFile.new(
          name: "plugins/custom-update/custom-update.php",
          content: fixture("plugins", "custom-update", "custom-update.php")
        )
      end
      let(:dependency_files) { [custom_file] }

      it "skips the plugin" do
        expect(dependencies).to be_empty
      end
    end

    context "with a plugin missing the Version header" do
      let(:no_version_file) do
        Dependabot::DependencyFile.new(
          name: "plugins/no-version/no-version.php",
          content: fixture("plugins", "no-version", "no-version.php")
        )
      end
      let(:dependency_files) { [no_version_file] }

      it "skips the plugin" do
        expect(dependencies).to be_empty
      end
    end

    context "with a child theme" do
      let(:child_theme_file) do
        Dependabot::DependencyFile.new(
          name: "themes/developer-starter-child/style.css",
          content: fixture("themes", "developer-starter-child", "style.css")
        )
      end
      let(:dependency_files) { [child_theme_file] }

      it "parses the child theme" do
        expect(dependencies.length).to eq(1)
        dep = dependencies.first
        expect(dep.name).to eq("developer-starter-child")
        expect(dep.version).to eq("1.0.0")
      end
    end
  end

  private

  def fixture(*path)
    File.read(File.join("spec/dependabot/wordpress/fixtures", *path))
  end
end
