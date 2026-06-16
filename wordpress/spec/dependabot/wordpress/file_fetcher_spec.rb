# typed: false
# frozen_string_literal: true

require "spec_helper"
require "dependabot/wordpress/file_fetcher"
require_common_spec "file_fetchers/shared_examples_for_file_fetchers"

RSpec.describe Dependabot::Wordpress::FileFetcher do
  let(:repo_contents_path) { build_tmp_repo(project_name) }
  let(:directory) { "/" }
  let(:project_name) { "simple" }
  let(:source) do
    Dependabot::Source.new(
      provider: "github",
      repo: "example/repo",
      directory: directory
    )
  end
  let(:file_fetcher_instance) do
    described_class.new(
      source: source,
      credentials: [],
      repo_contents_path: repo_contents_path
    )
  end

  before do
    allow(file_fetcher_instance).to receive_messages(commit: "sha", allow_beta_ecosystems?: true)
  end

  after do
    FileUtils.rm_rf(repo_contents_path)
  end

  it_behaves_like "a dependency file fetcher"

  describe ".required_files_in?" do
    subject { described_class.required_files_in?(filenames) }

    context "with PHP files" do
      let(:filenames) { %w(akismet.php readme.txt) }

      it { is_expected.to be(true) }
    end

    context "with style.css" do
      let(:filenames) { %w(style.css functions.php) }

      it { is_expected.to be(true) }
    end

    context "without relevant files" do
      let(:filenames) { %w(README.md package.json) }

      it { is_expected.to be(false) }
    end
  end

  describe "#fetch_files" do
    subject(:fetched_files) { file_fetcher_instance.fetch_files }

    context "with plugins and themes" do
      let(:project_name) { "simple" }

      it "fetches plugin and theme files" do
        expect(fetched_files.map(&:name)).to contain_exactly(
          "plugins/akismet/akismet.php",
          "plugins/hello-dolly/hello.php",
          "themes/developer-starter/style.css"
        )
      end
    end

    context "with plugins only" do
      let(:project_name) { "plugins_only" }

      it "fetches only plugin files" do
        expect(fetched_files.map(&:name)).to eq(["plugins/akismet/akismet.php"])
      end
    end

    context "with themes only" do
      let(:project_name) { "themes_only" }

      it "fetches only theme files" do
        expect(fetched_files.map(&:name)).to eq(["themes/developer-starter/style.css"])
      end
    end

    context "with no WordPress files" do
      let(:project_name) { "empty" }

      it "raises DependencyFileNotFound" do
        expect { fetched_files }.to raise_error(Dependabot::DependencyFileNotFound)
      end
    end

    context "when beta ecosystems are disabled" do
      before do
        allow(file_fetcher_instance).to receive(:allow_beta_ecosystems?).and_return(false)
      end

      it "raises DependencyFileNotFound" do
        expect { fetched_files }.to raise_error(Dependabot::DependencyFileNotFound)
      end
    end
  end
end
