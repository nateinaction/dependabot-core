# typed: strict
# frozen_string_literal: true

require "dependabot/dependency"
require "dependabot/file_parsers"
require "dependabot/file_parsers/base"
require "dependabot/wordpress/version"

module Dependabot
  module Wordpress
    class FileParser < Dependabot::FileParsers::Base
      extend T::Sig

      HEADER_REGEX_TEMPLATE = /^[ \t\/*#@]*%{name}\s*:\s*(.+)/i
      HEADER_READ_LENGTH = 8192

      PLUGIN_HEADERS = T.let({
        "Plugin Name" => :name,
        "Version" => :version,
        "Plugin URI" => :source_url,
        "Update URI" => :update_uri,
        "Requires at least" => :wp_requires,
        "Requires PHP" => :php_requires,
        "Requires Plugins" => :requires_plugins
      }.freeze, T::Hash[String, Symbol])

      THEME_HEADERS = T.let({
        "Theme Name" => :name,
        "Version" => :version,
        "Theme URI" => :source_url,
        "Update URI" => :update_uri,
        "Template" => :template,
        "Requires at least" => :wp_requires,
        "Requires PHP" => :php_requires
      }.freeze, T::Hash[String, Symbol])

      sig { override.returns(T::Array[Dependabot::Dependency]) }
      def parse
        dependencies = T.let([], T::Array[Dependabot::Dependency])

        dependency_files.each do |file|
          dep = if file.name.end_with?(".php")
                  parse_plugin(file)
                elsif file.name.end_with?("style.css")
                  parse_theme(file)
                end
          dependencies << dep if dep
        end

        dependencies
      end

      private

      sig { override.void }
      def check_required_files
        return if dependency_files.any?

        raise "No WordPress plugin or theme files found!"
      end

      sig { params(file: Dependabot::DependencyFile).returns(T.nilable(Dependabot::Dependency)) }
      def parse_plugin(file)
        headers = extract_headers(file, PLUGIN_HEADERS)
        return nil unless headers[:name]
        return nil unless headers[:version]
        return nil if custom_update_uri?(headers[:update_uri])

        slug = extract_slug(file)

        Dependabot::Dependency.new(
          name: slug,
          version: headers[:version],
          requirements: [{
            requirement: headers[:version],
            file: file.name,
            source: { type: :plugin },
            groups: [:plugins]
          }],
          package_manager: "wordpress",
          metadata: { dependency_type: :plugin }
        )
      end

      sig { params(file: Dependabot::DependencyFile).returns(T.nilable(Dependabot::Dependency)) }
      def parse_theme(file)
        headers = extract_headers(file, THEME_HEADERS)
        return nil unless headers[:name]
        return nil unless headers[:version]
        return nil if custom_update_uri?(headers[:update_uri])

        slug = extract_slug(file)

        Dependabot::Dependency.new(
          name: slug,
          version: headers[:version],
          requirements: [{
            requirement: headers[:version],
            file: file.name,
            source: { type: :theme },
            groups: [:themes]
          }],
          package_manager: "wordpress",
          metadata: { dependency_type: :theme }
        )
      end

      sig do
        params(
          file: Dependabot::DependencyFile,
          header_map: T::Hash[String, Symbol]
        ).returns(T::Hash[Symbol, T.nilable(String)])
      end
      def extract_headers(file, header_map)
        content = T.must(file.content)[0, HEADER_READ_LENGTH] || ""
        result = T.let({}, T::Hash[Symbol, T.nilable(String)])

        header_map.each do |header_string, key|
          pattern = Regexp.new(
            "^[ \\t\\/*#@]*#{Regexp.escape(header_string)}\\s*:\\s*(.+)",
            Regexp::IGNORECASE
          )
          match = content.match(pattern)
          result[key] = match ? clean_header_value(match[1].to_s) : nil
        end

        result
      end

      sig { params(value: String).returns(String) }
      def clean_header_value(value)
        value.gsub(%r{\s*\*/\s*$}, "").strip
      end

      sig { params(file: Dependabot::DependencyFile).returns(String) }
      def extract_slug(file)
        parts = file.name.split("/")
        if parts.length >= 2
          parts[-2]
        else
          File.basename(file.name, File.extname(file.name))
        end
      end

      sig { params(update_uri: T.nilable(String)).returns(T::Boolean) }
      def custom_update_uri?(update_uri)
        return false if update_uri.nil? || update_uri.empty?

        uri = update_uri.strip.downcase
        return false if uri.start_with?("https://api.wordpress.org")
        return false if uri.match?(%r{\Aw\.org/})

        true
      end
    end
  end
end

Dependabot::FileParsers.register("wordpress", Dependabot::Wordpress::FileParser)
