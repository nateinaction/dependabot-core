# typed: strict
# frozen_string_literal: true

require "dependabot/file_fetchers"
require "dependabot/file_fetchers/base"

module Dependabot
  module Wordpress
    class FileFetcher < Dependabot::FileFetchers::Base
      extend T::Sig

      PLUGIN_HEADER_REGEX = /^[ \t\/*#@]*Plugin Name\s*:/i
      DEFAULT_PLUGIN_DIRECTORY = "plugins"
      DEFAULT_THEME_DIRECTORY = "themes"

      sig { override.returns(String) }
      def self.required_files_message
        "Repo must contain a WordPress plugin or theme directory with PHP/CSS files."
      end

      sig { override.params(filenames: T::Array[String]).returns(T::Boolean) }
      def self.required_files_in?(filenames)
        filenames.any? { |f| f.end_with?(".php") || f == "style.css" }
      end

      sig { override.returns(T::Array[DependencyFile]) }
      def fetch_files
        unless allow_beta_ecosystems?
          raise Dependabot::DependencyFileNotFound.new(
            nil,
            "WordPress support is currently in beta. Set ALLOW_BETA_ECOSYSTEMS=true to enable it."
          )
        end

        fetched_files = []
        fetched_files += fetch_plugin_files
        fetched_files += fetch_theme_files

        return fetched_files if fetched_files.any?

        raise Dependabot::DependencyFileNotFound.new(nil, self.class.required_files_message)
      end

      sig { override.returns(T.nilable(T::Hash[Symbol, T.untyped])) }
      def ecosystem_versions
        nil
      end

      private

      sig { returns(String) }
      def plugin_directory
        options.fetch(:plugin_directory, DEFAULT_PLUGIN_DIRECTORY).to_s
      end

      sig { returns(String) }
      def theme_directory
        options.fetch(:theme_directory, DEFAULT_THEME_DIRECTORY).to_s
      end

      sig { returns(T::Array[DependencyFile]) }
      def fetch_plugin_files
        plugin_files = T.let([], T::Array[DependencyFile])

        plugin_dirs = repo_contents(dir: plugin_directory, raise_errors: false)
                      .select { |f| f.type == "dir" }

        plugin_dirs.each do |plugin_dir|
          subdir_path = File.join(plugin_directory, plugin_dir.name)
          php_entries = repo_contents(dir: subdir_path, raise_errors: false)
                        .select { |f| f.type == "file" && f.name.end_with?(".php") }

          php_entries.each do |entry|
            file_path = File.join(subdir_path, entry.name)
            file = fetch_file_from_host(file_path)
            content = T.must(file.content)
            next unless content[0, 8192]&.match?(PLUGIN_HEADER_REGEX)

            plugin_files << file
          end
        end

        plugin_files
      rescue Dependabot::DependencyFileNotFound
        []
      end

      sig { returns(T::Array[DependencyFile]) }
      def fetch_theme_files
        theme_files = T.let([], T::Array[DependencyFile])

        theme_dirs = repo_contents(dir: theme_directory, raise_errors: false)
                     .select { |f| f.type == "dir" }

        theme_dirs.each do |theme_dir|
          subdir_path = File.join(theme_directory, theme_dir.name)
          css_entries = repo_contents(dir: subdir_path, raise_errors: false)
                        .select { |f| f.type == "file" && f.name == "style.css" }

          css_entries.each do |entry|
            file_path = File.join(subdir_path, entry.name)
            theme_files << fetch_file_from_host(file_path)
          end
        end

        theme_files
      rescue Dependabot::DependencyFileNotFound
        []
      end
    end
  end
end

Dependabot::FileFetchers.register("wordpress", Dependabot::Wordpress::FileFetcher)
